# Reclaims cargo build output under the shared Capy work directory.
#
# Cargo leaves evidence of its own in a target directory, and this goes by that
# evidence rather than by names, which lie: a checkout that ships a release/
# directory of packaging scripts is source, not build output. A directory is a
# target directory when it holds the CACHEDIR.TAG cargo writes (other tools
# write that file too, so its text has to name cargo) or .rustc_info.json, or
# when a profile directory inside it holds both deps/ and .fingerprint/. Both
# shapes count: a checkout's target/, which is cargo's alone and is removed
# whole, and a top-level directory that cargo was pointed at directly. That one
# may also hold things a crew put there, so only cargo's output in it is
# removed: its profile directories, the ones a build for an explicit --target
# puts one level down, and the tag and .rustc_info.json.
#
# Two things must hold before one is removed. Nothing may be using it: no
# process may have a path under it as its working directory, open, or mapped,
# and cargo must not be holding its build locks in it. And it must be idle,
# meaning nothing anywhere under it has been written for --idle-hours. On top of
# that a crew's target directories are capped at --crew-budget-gib, oldest
# first, and a filesystem with less than --free-floor-gib free drops to the
# shorter --pressure-idle-hours window.
#
# The NixOS module wraps this file in writeShellApplication, which supplies bash,
# coreutils, findutils, grep and flock, and turns on errexit, nounset and
# pipefail.

usage() {
  cat <<'EOF'
usage: capy-work-prune [options]

  --work-dir DIR           directory holding the crews' checkouts and their
                           target directories (default: $HOME/.capy/work)
  --crew-budget-gib N      ceiling on the target directories of one crew, in
                           GiB (default: 100)
  --idle-hours N           a target directory is idle once nothing under it has
                           been written for this long (default: 24)
  --pressure-idle-hours N  shorter idle window used while free space is below
                           the floor (default: 2)
  --free-floor-gib N       free space on the work directory's filesystem below
                           which every idle target directory is pruned
                           (default: 200)
  --state-dir DIR          where the scan cache, the lock and the record of
                           deletes in progress live (the service sets this); a
                           run that deletes needs one, and a dry run without
                           one scans every time and cannot tell what an
                           interrupted delete left behind
  --dry-run                print what would be removed and change nothing
  --full                   scan even when the cheap checks found nothing to do
  -h, --help               print this text
EOF
}

log() {
  printf 'capy-work-prune: %s\n' "$*"
}

die() {
  printf 'capy-work-prune: %s\n' "$*" >&2
  exit 2
}

work_dir="${HOME:-/nonexistent}/.capy/work"
crew_budget_gib=100
idle_hours=24
pressure_idle_hours=2
free_floor_gib=200
state_dir=""
dry_run=0
full=0

parse_arguments() {
  local name
  while (( $# )); do
    case $1 in
      --work-dir | --crew-budget-gib | --idle-hours | --pressure-idle-hours | --free-floor-gib | --state-dir)
        (( $# >= 2 )) || die "$1 needs a value"
        name=${1#--}
        printf -v "${name//-/_}" '%s' "$2"
        shift 2
        ;;
      --dry-run)
        dry_run=1
        shift
        ;;
      --full)
        full=1
        shift
        ;;
      -h | --help)
        usage
        exit 0
        ;;
      *)
        usage >&2
        die "unknown argument: $1"
        ;;
    esac
  done
}

check_arguments() {
  local name value
  for name in crew_budget_gib idle_hours pressure_idle_hours free_floor_gib; do
    value=${!name}
    [[ $value =~ ^[1-9][0-9]*$ ]] || die "--${name//_/-} must be a positive integer, got: $value"
  done
  (( pressure_idle_hours <= idle_hours )) ||
    die "--pressure-idle-hours ($pressure_idle_hours) must not exceed --idle-hours ($idle_hours)"
  (( dry_run )) || [[ -n $state_dir ]] ||
    die "a run that deletes needs --state-dir, to record the deletes it starts"
}

# KiB free on the filesystem that holds a path, as the filesystem itself counts
# it: reserved blocks are not available to this user.
available_kib() {
  local free
  read -r free < <(df --output=avail -k -- "$1" | tail -n 1)
  [[ $free =~ ^[0-9]+$ ]] || die "cannot read the free space of $1"
  printf '%s\n' "$free"
}

# KiB a path occupies on disk. Disk usage, not apparent size: this is what
# removing it gives back. Fails for a path du cannot read, which is that entry's
# problem and not the run's.
disk_kib() {
  local used
  read -r used _ < <(du -sk -- "$1")
  [[ $used =~ ^[0-9]+$ ]] || return 1
  printf '%s\n' "$used"
}

# KiB as a readable size: MiB below a GiB, GiB above.
size_text() {
  if (( $1 >= 1048576 )); then
    printf '%s GiB' "$(($1 / 1048576))"
  else
    printf '%s MiB' "$(($1 / 1024))"
  fi
}

proc_name() {
  local name
  read -r name <"/proc/$1/comm" 2>/dev/null || name="?"
  printf '%s\n' "$name"
}

# Cargo holds an exclusive flock in the profile directory for as long as a build
# runs, and locks are per-inode: a probe here sees a cargo build that /proc
# cannot, in another mount namespace or under another uid. A lock file that is
# not there is no evidence of use, not evidence of disuse.
cargo_lock_held() {
  local dir=$1 profile lock
  for profile in debug release; do
    for lock in "$dir/$profile"/.cargo-build-lock "$dir/$profile"/.cargo-lock "$dir/$profile"/.cargo-artifact-lock; do
      [[ -e $lock ]] || continue
      if ! flock -n -- "$lock" true; then
        printf 'cargo holds %s\n' "$lock"
        return 0
      fi
    done
  done
  return 1
}

declare -A busy_paths=()

# Collects, once per run, every path under the work directory that a process has
# as its working directory, open, or mapped, and the process it belongs to.
# Mappings count because a test binary whose descriptor has closed keeps its
# blocks alive. /proc is read directly rather than through lsof, which is not in
# this module's closure.
collect_busy_paths() {
  local pid_dir pid link fd line
  # "address perms offset dev inode", each followed by one space, then spaces
  # that pad the path out to a fixed column, then the path, which may itself
  # hold spaces.
  local maps_line='^([^ ]+ ){5} *(/.*)$'
  for pid_dir in /proc/[0-9]*; do
    pid=${pid_dir#/proc/}
    [[ $pid == "$$" ]] && continue
    if link=$(readlink -- "$pid_dir/cwd" 2>/dev/null); then
      link=${link% (deleted)}
      if [[ $link == "$work_dir" || $link == "$work_dir"/* ]]; then
        busy_paths["$link"]="pid $pid ($(proc_name "$pid")) has it as its working directory"
      fi
    fi
    for fd in "$pid_dir"/fd/*; do
      link=$(readlink -- "$fd" 2>/dev/null) || continue
      link=${link% (deleted)}
      if [[ $link == "$work_dir"/* ]]; then
        busy_paths["$link"]="pid $pid ($(proc_name "$pid")) has it open"
      fi
    done
    if [[ -r $pid_dir/maps ]] && grep -qsF -- "$work_dir/" "$pid_dir/maps"; then
      while IFS= read -r line; do
        [[ $line =~ $maps_line ]] || continue
        link=${BASH_REMATCH[2]% (deleted)}
        busy_paths["$link"]="pid $pid ($(proc_name "$pid")) has it mapped"
      done < <(grep -F -- "$work_dir/" "$pid_dir/maps")
    fi
  done
}

# Prints why a target directory counts as in use, and fails when nothing is
# using it.
busy_reason() {
  local candidate=$1 key reason
  if reason=$(cargo_lock_held "$candidate"); then
    printf '%s\n' "$reason"
    return 0
  fi
  for key in "${!busy_paths[@]}"; do
    if [[ $key == "$candidate" || $key == "$candidate"/* ]]; then
      printf '%s\n' "${busy_paths[$key]}"
      return 0
    fi
  done
  return 1
}

# Seconds since anything anywhere under a target directory was written. Cargo's
# writes land in deps/, .fingerprint/ and incremental/ far more than in the
# profile directory itself, so the profile directory's own mtime says almost
# nothing about the last build.
activity_age() {
  local dir=$1 newest now
  newest=$(find "$dir" -printf '%T@\n' 2>/dev/null | sort -g | tail -n 1)
  newest=${newest%%.*}
  [[ $newest =~ ^[0-9]+$ ]] || return 1
  now=$(date +%s)
  newest=$((now - newest))
  (( newest >= 0 )) || newest=0
  printf '%s\n' "$newest"
}

# Cargo's own marks on a target directory it created, or its own work inside a
# profile directory. Nothing else is build output, whatever the directory is
# called.
is_target_dir() {
  local dir=$1 profile
  if is_cargo_tag "$dir/CACHEDIR.TAG" || [[ -f $dir/.rustc_info.json && ! -L $dir/.rustc_info.json ]]; then
    return 0
  fi
  for profile in debug release; do
    if is_profile_dir "$dir/$profile"; then
      return 0
    fi
  done
  return 1
}

# Whether a file is the cache directory tag cargo writes. The tag's signature
# line is the convention's and every tool's, so the line naming cargo is what
# tells cargo's apart from a virtualenv's or a test cache's. Cargo writes the
# tag as a file, so a symlink is never one, wherever it points.
is_cargo_tag() {
  [[ -f $1 && ! -L $1 ]] && grep -qxF -- '# This file is a cache directory tag created by cargo.' "$1"
}

# Whether a directory is one cargo builds a profile into, whatever the profile
# is called.
is_profile_dir() {
  [[ -d $1/deps && -d $1/.fingerprint && ! -L $1 ]]
}

# Whether a path is a top-level entry of the work directory that cargo was
# pointed at directly, as opposed to a checkout's target/ or a delete this
# script started.
is_direct_target() {
  local relative=${1#"$work_dir"/}
  [[ $relative != */* && -z ${staged_markers[$1]:-} ]]
}

# The parts of a directory cargo was pointed at directly that are cargo's own,
# relative to it and NUL-terminated: each profile directory, each one a level
# down where a build for an explicit --target puts it, then .rustc_info.json
# and cargo's tag last, so a delete interrupted partway leaves the marks on
# whatever is still there. Anything else in the directory is not listed.
cargo_output() {
  local dir=$1 child grandchild
  for child in "$dir"/*; do
    [[ -d $child && ! -L $child ]] || continue
    if is_profile_dir "$child"; then
      printf '%s\0' "${child##*/}"
      continue
    fi
    for grandchild in "$child"/*; do
      if is_profile_dir "$grandchild"; then
        printf '%s\0' "${child##*/}/${grandchild##*/}"
      fi
    done
  done
  if [[ -f $dir/.rustc_info.json && ! -L $dir/.rustc_info.json ]]; then
    printf '%s\0' .rustc_info.json
  fi
  if is_cargo_tag "$dir/CACHEDIR.TAG" && [[ ! -L $dir/CACHEDIR.TAG ]]; then
    printf '%s\0' CACHEDIR.TAG
  fi
}

# KiB that removing a target directory gives back: all of it, or for one cargo
# was pointed at directly, only cargo's output in it.
target_kib() {
  local path=$1 used
  local -a items
  if ! is_direct_target "$path"; then
    disk_kib "$path"
    return
  fi
  mapfile -d '' items < <(cargo_output "$path")
  if (( ${#items[@]} == 0 )); then
    printf '0\n'
    return 0
  fi
  read -r used _ < <(du -skc -- "${items[@]/#/$path/}" | tail -n 1)
  [[ $used =~ ^[0-9]+$ ]] || return 1
  printf '%s\n' "$used"
}

# Moves cargo's output out of a directory cargo was pointed at directly into
# the marked directory beside it, which the caller has just created, each item
# keeping its place relative to the directory, and removes the directories that
# this leaves empty. Fails when anything could not be moved; what was moved is
# in the marked directory either way, and is cargo's alone.
stage_cargo_output() {
  local dir=$1 doomed=$2 item parent status=0
  local -a items
  mapfile -d '' items < <(cargo_output "$dir")
  for item in "${items[@]}"; do
    parent=$(dirname -- "$item")
    if ! mkdir -p -- "$doomed/$parent" || ! mv -T -- "$dir/$item" "$doomed/$item"; then
      status=1
      continue
    fi
    # Only a --target directory whose last profile just left is empty here, and
    # one that could not be removed costs nothing.
    if [[ $parent != . ]]; then
      rmdir --ignore-fail-on-non-empty -- "$dir/$parent" || true
    fi
  done
  rmdir --ignore-fail-on-non-empty -- "$dir" || true
  return "$status"
}

# Every marked directory a delete of this script's has created and not yet
# finished, recorded in the state directory before the directory is created.
# Only these are deleted as they stand: a name that merely looks like a marker
# is a crew's, and takes the same rules as any other entry.
declare -A staged_markers=()

# Reads the record of deletes in progress, if there is a state directory. A
# record that does not have exactly the shape of a marker this script creates
# under this work directory is ignored, and dropped the next time the record is
# written: a damaged record must never name a checkout or a target/ itself.
load_staged_markers() {
  local marker
  local -a markers
  [[ -n $state_dir && -r $state_dir/staged ]] || return 0
  mapfile -d '' markers <"$state_dir/staged"
  for marker in "${markers[@]}"; do
    if ! is_marker_path "$marker"; then
      log "ignored (not a marker this script creates under $work_dir) recorded $marker"
      continue
    fi
    staged_markers["$marker"]=1
  done
}

# Replaces the record of deletes in progress with staged_markers, NUL-separated
# because a path may hold a newline. The new record and the rename that puts it
# in place both reach the disk before this returns, so a marker created after a
# power loss can never outlive its record.
save_staged_markers() {
  local marker tmp=$state_dir/staged.tmp
  for marker in "${!staged_markers[@]}"; do
    printf '%s\0' "$marker"
  done >"$tmp" &&
    sync -- "$tmp" &&
    mv -- "$tmp" "$state_dir/staged" &&
    sync -- "$state_dir"
}

# Records a marked directory before it is created, so a run that is cut short
# after creating it leaves one the next run knows to be its own.
record_staged_marker() {
  staged_markers["$1"]=1
  if ! save_staged_markers; then
    unset 'staged_markers[$1]'
    return 1
  fi
}

# Drops a marked directory that no longer exists from the record. A record that
# cannot be updated keeps naming a path that is gone, which the next run drops.
forget_staged_marker() {
  unset 'staged_markers[$1]'
  if ! save_staged_markers; then
    log "could not update $state_dir/staged after $1 went"
  fi
}

# The crew a work directory entry belongs to: its name, lowercased, without the
# mark of an interrupted delete and without a trailing -target, so CRU-334,
# CRU-334/target and CRU-334-target all count against one crew's budget.
crew_of() {
  local name=${1,,}
  name=${name%.pruning.*}
  printf '%s\n' "${name%-target}"
}

target_dirs=()
target_crews=()
target_kibs=()
target_ages=()
target_removed=()
target_kept=()
removed_count=0
removed_kib=0
declare -A seen_paths=()

add_target() {
  local path=$1 crew=$2 age size
  [[ -n ${seen_paths[$path]:-} ]] && return 0
  seen_paths["$path"]=1
  age=$(activity_age "$path") || return 0
  size=$(target_kib "$path") || {
    log "skipped (cannot measure) $path"
    return 0
  }
  target_dirs+=("$path")
  target_crews+=("$crew")
  target_kibs+=("$size")
  target_ages+=("$age")
  target_removed+=(0)
  target_kept+=(0)
}

scan_targets() {
  local entry base leftover held
  for entry in "$work_dir"/*; do
    [[ -d $entry && ! -L $entry ]] || continue
    base=$(basename -- "$entry")
    if is_target_dir "$entry/target" && [[ ! -L $entry/target ]]; then
      add_target "$entry/target" "$(crew_of "$base")"
    elif is_target_dir "$entry"; then
      add_target "$entry" "$(crew_of "$base")"
    fi
  done
  # A delete that was interrupted leaves a marked directory, beside a
  # checkout's target or beside a top-level target directory, that the state
  # directory recorded before creating it. It is this script's own unfinished
  # work and takes the same rules; the entry loop may already have collected
  # it. One that is gone is dropped from the record.
  for leftover in "${!staged_markers[@]}"; do
    if [[ ! -e $leftover && ! -L $leftover ]]; then
      (( dry_run )) || forget_staged_marker "$leftover"
      continue
    fi
    if [[ ! -d $leftover || -L $leftover ]]; then
      log "ignored (not a directory) recorded $leftover"
      (( dry_run )) || forget_staged_marker "$leftover"
      continue
    fi
    base=${leftover#"$work_dir"/}
    add_target "$leftover" "$(crew_of "${base%%/*}")"
  done
  held=$(total_kib)
  log "found ${#target_dirs[@]} target directories holding $(size_text "$held")"
}

total_kib() {
  local index total=0
  for index in "${!target_dirs[@]}"; do
    (( target_removed[index] )) && continue
    total=$((total + target_kibs[index]))
  done
  printf '%s\n' "$total"
}

# KiB still held by one crew's target directories.
crew_kib() {
  local crew=$1 index total=0
  for index in "${!target_dirs[@]}"; do
    [[ ${target_crews[index]} == "$crew" ]] || continue
    (( target_removed[index] )) && continue
    total=$((total + target_kibs[index]))
  done
  printf '%s\n' "$total"
}

# Whether a path is one this script may remove: a top-level entry of the work
# directory, or a checkout's target/ under it, or a marker this script made of
# either.
is_target_path() {
  local path=$1 relative entry
  relative=${path#"$work_dir"/}
  entry=${relative%%/*}
  [[ $relative != "$path" && $entry != . && $entry != .. &&
    $relative =~ ^[^/]+(/target)?(\.pruning\.[0-9]+\.[0-9]+)?$ ]]
}

# Whether a path has exactly the shape of a marked directory this script
# creates: a target path with the one marker of epoch and pid it appends.
is_marker_path() {
  is_target_path "$1" && [[ $1 =~ \.pruning\.[0-9]+\.[0-9]+$ ]]
}

# Removes one target directory under the given rule, after checking again that
# nothing is using it, and logs what went and why. A directory it kept stays in
# target_dirs, which is how a caller counting freed space sees that nothing came
# back. Every call settles its directory for the rest of the run, as removed or
# as kept, so a caller looping until a budget holds always moves on.
prune_target() {
  local index=$1 rule=$2
  local path=${target_dirs[$index]} size=${target_kibs[$index]} reason doomed status=0
  local staged=1 deleted=1 left kib measured what=$path
  if (( target_removed[index] || target_kept[index] )); then
    return 0
  fi
  if ! is_target_path "$path"; then
    target_kept[index]=1
    log "skipped (not a target directory of the work directory) $path"
    return 0
  fi
  if [[ ! -d $path ]] || [[ -L $path ]]; then
    target_kept[index]=1
    log "skipped (gone since the scan) $path"
    return 0
  fi
  # A recorded marker is one this script created itself, and a delete it did
  # not finish may have taken the cargo marks with it, so every other path has
  # to still look like build output.
  if [[ -z ${staged_markers[$path]:-} ]] && ! is_target_dir "$path"; then
    target_kept[index]=1
    log "skipped (no cargo marks since the scan) $path"
    return 0
  fi
  reason=$(busy_reason "$path") || status=$?
  if (( status == 0 )); then
    target_kept[index]=1
    log "kept (in use) $path: $reason"
    return 0
  fi
  if (( status != 1 )); then
    # The check itself broke. Anything but a clean "nothing is using it" is
    # treated as a reason to leave the directory alone.
    target_kept[index]=1
    log "kept (the in-use check failed, status ${status}) $path"
    return 0
  fi
  if is_direct_target "$path"; then
    what="cargo's output in $path"
  fi
  if (( dry_run )); then
    log "would remove (rule ${rule}, $(size_text "$size")) $what"
  else
    # Renamed before it is deleted, so a build that starts during the delete
    # finds a missing directory instead of losing files one at a time. The
    # rename cannot cross a filesystem, and --one-file-system keeps the delete
    # off other devices; a bind mount of the same filesystem is the one case it
    # cannot see. Each marked directory is recorded in the state directory
    # before it is created. A recorded one was left by an interrupted delete,
    # so it is deleted as it stands instead of collecting another marker. A
    # directory cargo was pointed at directly keeps its place and everything
    # that is not cargo's: only cargo's output moves to the marked directory. Any step failing is this entry's problem and not the
    # run's: it is kept, and a delete that fails partway leaves its marker for
    # the next run to finish.
    doomed=$path
    if [[ -z ${staged_markers[$path]:-} ]]; then
      doomed="${path}.pruning.$(date +%s).$$"
      if ! record_staged_marker "$doomed"; then
        target_kept[index]=1
        log "kept (recording the delete in $state_dir failed) $path"
        return 0
      fi
      if is_direct_target "$path"; then
        # A marked directory that already exists is not this delete's, so it is
        # neither filled, deleted, nor left in the record.
        if ! mkdir -- "$doomed"; then
          forget_staged_marker "$doomed"
          target_kept[index]=1
          log "kept (creating $doomed for the delete failed) $path"
          return 0
        fi
        stage_cargo_output "$path" "$doomed" || staged=0
      elif ! mv -T -- "$path" "$doomed"; then
        forget_staged_marker "$doomed"
        target_kept[index]=1
        log "kept (renaming it for the delete failed) $path"
        return 0
      fi
    fi
    if [[ -e $doomed ]] && ! rm -rf --one-file-system --preserve-root -- "$doomed"; then
      deleted=0
    fi
    if [[ ! -e $doomed ]]; then
      forget_staged_marker "$doomed"
    fi
    if (( ! staged || ! deleted )); then
      # Whatever did go is gone, so the budget counts what is left rather than
      # what was there, unless what is left cannot be measured.
      target_kept[index]=1
      left=0
      measured=1
      if [[ -e $doomed ]]; then
        if kib=$(disk_kib "$doomed"); then
          left=$((left + kib))
        else
          measured=0
        fi
      fi
      if [[ $doomed != "$path" && -d $path ]] && is_direct_target "$path"; then
        if kib=$(target_kib "$path"); then
          left=$((left + kib))
        else
          measured=0
        fi
      fi
      if (( measured )); then
        target_kibs[index]=$left
      fi
      if (( ! staged )); then
        log "kept (moving cargo's output out for the delete failed, $(size_text "${target_kibs[index]}") left) $path"
      else
        log "kept (the delete failed, $(size_text "${target_kibs[index]}") left in $doomed) $path"
      fi
      return 0
    fi
    log "removed (rule ${rule}, $(size_text "$size")) $what"
  fi
  target_removed[index]=1
  removed_count=$((removed_count + 1))
  removed_kib=$((removed_kib + size))
}

enforce_free_floor() {
  local index
  (( free_kib < floor_kib )) || return 0
  log "free space $(size_text "$free_kib") is below the ${free_floor_gib} GiB floor: pruning everything idle for more than ${pressure_idle_hours}h"
  for index in "${!target_dirs[@]}"; do
    (( target_ages[index] >= pressure_seconds )) || continue
    prune_target "$index" "free-floor"
  done
  return 0
}

enforce_idle_window() {
  local index
  for index in "${!target_dirs[@]}"; do
    (( target_ages[index] >= idle_seconds )) || continue
    prune_target "$index" "idle"
  done
  return 0
}

enforce_crew_budgets() {
  local crew index oldest total crew_indices
  local -a crews
  ((${#target_crews[@]})) || return 0
  while read -r crew; do
    crews+=("$crew")
  done < <(printf '%s\n' "${target_crews[@]}" | sort -u)

  for crew in "${crews[@]}"; do
    total=$(crew_kib "$crew")
    (( total > crew_budget_kib )) || continue
    log "crew ${crew:-(unnamed)} holds $(size_text "$total"), over its ${crew_budget_gib} GiB budget: oldest first"
    crew_indices=()
    for index in "${!target_dirs[@]}"; do
      [[ ${target_crews[index]} == "$crew" ]] && crew_indices+=("$index")
    done
    while (( total > crew_budget_kib )); do
      oldest=-1
      for index in "${crew_indices[@]}"; do
        (( target_removed[index] || target_kept[index] )) && continue
        if (( oldest < 0 || target_ages[index] > target_ages[oldest] )); then
          oldest=$index
        fi
      done
      # Every directory left in this crew has been kept, because it is in use
      # or could not be removed, and space is not what a budget dispute with a
      # running build is worth.
      (( oldest >= 0 )) || break
      # A kept directory is not tried again, so the next pass picks the
      # next-oldest one.
      prune_target "$oldest" "budget"
      total=$(crew_kib "$crew")
    done
  done
  return 0
}

# Cheap checks that decide whether walking every target directory is worth it:
# plenty of free space, and a recent scan that found every crew inside its
# budget, means nothing can need doing. A filesystem under the floor, a missing
# or stale scan, or a crew the last scan found over budget all send it on to the
# full scan.
scan_would_be_pointless() {
  local scanned_at tag crew kib now
  if (( free_kib < floor_kib )); then
    return 1
  fi
  if [[ -z $state_dir || ! -r $state_dir/scan ]]; then
    return 1
  fi
  read -r tag scanned_at <"$state_dir/scan" || return 1
  [[ $tag == "scanned_at" && $scanned_at =~ ^[0-9]+$ ]] || return 1
  now=$(date +%s)
  if (( scanned_at > now || now - scanned_at > cache_seconds )); then
    return 1
  fi
  while read -r tag crew kib; do
    [[ $tag == "crew" ]] || continue
    if (( kib > crew_budget_kib )); then
      return 1
    fi
  done <"$state_dir/scan"
  log "free space $(size_text "$free_kib"), every crew inside its budget as of the scan $(((now - scanned_at) / 60)) minutes ago: nothing to do"
  return 0
}

write_cache() {
  local crew tmp
  local -a crews
  [[ -n $state_dir ]] || return 0
  (( dry_run )) && return 0
  while read -r crew; do
    crews+=("$crew")
  done < <(printf '%s\n' "${target_crews[@]}" | sort -u)
  tmp="$state_dir/scan.tmp"
  {
    printf 'scanned_at %s\n' "$(date +%s)"
    for crew in "${crews[@]}"; do
      printf 'crew %s %s\n' "${crew:-(unnamed)}" "$(crew_kib "$crew")"
    done
  } >"$tmp"
  mv -- "$tmp" "$state_dir/scan"
}

main() {
  parse_arguments "$@"
  check_arguments

  crew_budget_kib=$((crew_budget_gib * 1048576))
  floor_kib=$((free_floor_gib * 1048576))
  idle_seconds=$((idle_hours * 3600))
  pressure_seconds=$((pressure_idle_hours * 3600))
  # A scan the hourly run may trust: one day, which is what the daily run
  # replaces long before a crew's drift can matter.
  cache_seconds=$((24 * 3600))

  if [[ ! -d $work_dir ]]; then
    log "no work directory at $work_dir: nothing to prune"
    return 0
  fi
  # One shape of path from here on, so the containment check before an rm
  # compares like with like.
  work_dir=$(realpath -- "$work_dir")

  if (( dry_run )); then
    log "dry run: nothing will be removed"
  elif [[ -n $state_dir ]]; then
    mkdir -p -- "$state_dir"
    exec 9>"$state_dir/lock"
    if ! flock -n 9; then
      log "another run holds $state_dir/lock: leaving it alone"
      exit 0
    fi
  fi
  load_staged_markers

  free_kib=$(available_kib "$work_dir")
  if (( ! full )) && scan_would_be_pointless; then
    return 0
  fi

  scan_targets
  collect_busy_paths
  enforce_free_floor
  enforce_idle_window
  enforce_crew_budgets
  write_cache

  if (( dry_run == 0 && removed_count > 0 )); then
    free_kib=$(available_kib "$work_dir")
  fi
  log "finished: ${removed_count} target directories, $(size_text "$removed_kib"), free space now $(size_text "$free_kib")"
  if (( free_kib < floor_kib )); then
    log "warning: still $(size_text "$free_kib") free, below the ${free_floor_gib} GiB floor; everything else is in use or recent"
  fi
}

main "$@"
