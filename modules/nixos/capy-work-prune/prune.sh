# Reclaims cargo build output under the shared Capy work directory.
#
# A target directory is found by shape, never by name: it is a top-level
# directory that itself holds debug/ or release/, or the target/ of a checkout
# beside it. Two things must hold before one is removed: nothing may be using it
# (busy_reason), and it must be idle, meaning neither debug/ nor release/ has
# been written for --idle-hours. On top of that a crew's target directories are
# capped at --crew-budget-gib, oldest first, and a filesystem with less than
# --free-floor-gib free drops to the shorter --pressure-idle-hours window.
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
  --idle-hours N           a target directory is idle once neither debug/ nor
                           release/ has been written for this long (default: 24)
  --pressure-idle-hours N  shorter idle window used while free space is below
                           the floor (default: 2)
  --free-floor-gib N       free space on the work directory's filesystem below
                           which every idle target directory is pruned
                           (default: 200)
  --state-dir DIR          where the scan cache and the lock live; without one
                           every run scans and no run caches (the service sets
                           this)
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
  while (( $# )); do
    case $1 in
      --work-dir)
        work_dir=${2:-}
        shift 2
        ;;
      --crew-budget-gib)
        crew_budget_gib=${2:-}
        shift 2
        ;;
      --idle-hours)
        idle_hours=${2:-}
        shift 2
        ;;
      --pressure-idle-hours)
        pressure_idle_hours=${2:-}
        shift 2
        ;;
      --free-floor-gib)
        free_floor_gib=${2:-}
        shift 2
        ;;
      --state-dir)
        state_dir=${2:-}
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
# removing it gives back.
disk_kib() {
  local used
  read -r used _ < <(du -sk -- "$1")
  [[ $used =~ ^[0-9]+$ ]] || die "cannot measure the size of $1"
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

# Prints why a target directory counts as in use, and fails when nothing is using
# it. Walks /proc directly rather than calling lsof, which is not in this
# module's closure: a process's working directory, its open descriptors, and the
# files it has mapped (a test binary the process has finished opening but still
# has mapped keeps the file's blocks alive, so a mapping counts too). Processes
# of other users are invisible here, which is enough: everything under the work
# directory is built as its owner.
busy_reason() {
  local real pid_dir pid link fd
  real=$(realpath -- "$1")
  for pid_dir in /proc/[0-9]*; do
    pid=${pid_dir#/proc/}
    [[ $pid == "$$" ]] && continue
    if link=$(readlink -- "$pid_dir/cwd" 2>/dev/null); then
      link=${link% (deleted)}
      if [[ $link == "$real" || $link == "$real"/* ]]; then
        printf 'pid %s (%s) has it as its working directory\n' "$pid" "$(proc_name "$pid")"
        return 0
      fi
    fi
    for fd in "$pid_dir"/fd/*; do
      link=$(readlink -- "$fd" 2>/dev/null) || continue
      link=${link% (deleted)}
      if [[ $link == "$real" || $link == "$real"/* ]]; then
        printf 'pid %s (%s) has %s open\n' "$pid" "$(proc_name "$pid")" "$link"
        return 0
      fi
    done
    if [[ -r $pid_dir/maps ]] && grep -qsF -- "$real/" "$pid_dir/maps"; then
      printf 'pid %s (%s) has one of its files mapped\n' "$pid" "$(proc_name "$pid")"
      return 0
    fi
  done
  return 1
}

# Seconds since either Cargo profile directory under a target directory was last
# written, which is when cargo last added or removed anything there. Fails when
# the directory holds neither, so it stopped being a target directory.
activity_age() {
  local dir=$1 newest=0 stamp sub age now
  for sub in debug release; do
    [[ -d $dir/$sub ]] || continue
    stamp=$(stat -c %Y -- "$dir/$sub") || return 1
    if (( stamp > newest )); then
      newest=$stamp
    fi
  done
  (( newest != 0 )) || return 1
  now=$(date +%s)
  age=$((now - newest))
  (( age >= 0 )) || age=0
  printf '%s\n' "$age"
}

is_target_dir() {
  [[ -d $1/debug || -d $1/release ]]
}

# The crew a work directory entry belongs to: its name, lowercased, with a
# trailing -target dropped, so CRU-334, CRU-334/target and CRU-334-target all
# count against one crew's budget.
crew_of() {
  local name=${1,,}
  printf '%s\n' "${name%-target}"
}

target_dirs=()
target_crews=()
target_kibs=()
target_ages=()
target_removed=()
removed_count=0
removed_kib=0

scan_targets() {
  local entry base path crew size age held
  for entry in "$work_dir"/*; do
    [[ -d $entry && ! -L $entry ]] || continue
    base=$(basename -- "$entry")
    if is_target_dir "$entry"; then
      path=$entry
    elif is_target_dir "$entry/target" && [[ ! -L $entry/target ]]; then
      path=$entry/target
    else
      continue
    fi
    age=$(activity_age "$path") || continue
    size=$(disk_kib "$path")
    crew=$(crew_of "$base")
    target_dirs+=("$path")
    target_crews+=("$crew")
    target_kibs+=("$size")
    target_ages+=("$age")
    target_removed+=(0)
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

# Removes one target directory under the given rule, after checking again that
# nothing is using it, and logs what went and why. A directory it kept stays in
# target_dirs, which is how a caller counting freed space sees that nothing came
# back.
prune_target() {
  local index=$1 rule=$2
  local path=${target_dirs[$index]} size=${target_kibs[$index]} reason
  if (( target_removed[index] )); then
    return 0
  fi
  assert_target_path "$path"
  if [[ ! -d $path ]] || [[ -L $path ]]; then
    log "skipped (gone since the scan) $path"
    return 0
  fi
  if ! is_target_dir "$path"; then
    log "skipped (no debug/ or release/ since the scan) $path"
    return 0
  fi
  if reason=$(busy_reason "$path"); then
    log "kept (in use) $path: $reason"
    return 0
  fi
  target_removed[index]=1
  removed_count=$((removed_count + 1))
  removed_kib=$((removed_kib + size))
  if (( dry_run )); then
    log "would remove (rule ${rule}, $(size_text "$size")) $path"
    return 0
  fi
  rm -rf --one-file-system --preserve-root -- "$path"
  log "removed (rule ${rule}, $(size_text "$size")) $path"
}

# Last line of defence before an rm -rf: the path has to be a top-level entry of
# the work directory or a checkout's target/ under it, and never a symlink out of
# it.
assert_target_path() {
  local path=$1 relative
  relative=${path#"$work_dir"/}
  [[ $relative != "$path" && $relative =~ ^[^/]+(/target)?$ ]] ||
    die "refusing to remove $path: not a target directory of $work_dir"
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
  local crew index oldest before total crew_indices
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
        (( target_removed[index] )) && continue
        if (( oldest < 0 || target_ages[index] > target_ages[oldest] )); then
          oldest=$index
        fi
      done
      (( oldest >= 0 )) || break
      before=$total
      prune_target "$oldest" "budget"
      total=$(crew_kib "$crew")
      # Everything left in this crew is in use, and space is not what a budget
      # dispute with a running build is worth.
      (( total < before )) || break
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
  if (( now - scanned_at > cache_seconds )); then
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

  free_kib=$(available_kib "$work_dir")
  if (( ! full )) && scan_would_be_pointless; then
    return 0
  fi

  scan_targets
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
