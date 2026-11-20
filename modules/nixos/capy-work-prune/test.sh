# Fake-tree tests for capy-work-prune.
#
# Every case builds its own work directory under a scratch root, ages it with
# touch, runs the prune command given as the first argument against it, and
# checks what is left and what the run logged. Processes that hold a directory
# are started here and killed on exit. The cases rely on permissions to make a
# file undeletable, so they refuse to run as root.
#
# Wrapped in writeShellApplication by test.nix, which supplies coreutils,
# findutils, grep and util-linux, and turns on errexit, nounset and pipefail.

prune=${1:?usage: capy-work-prune-test PRUNE-COMMAND}

if [[ $(id -u) == 0 ]]; then
  printf 'capy-work-prune-test: refusing to run as root, which can delete anything\n' >&2
  exit 2
fi

root=$(realpath -- "$(mktemp -d)")
failures=0
holders=()

cleanup() {
  local pid
  for pid in "${holders[@]}"; do
    kill "$pid" 2>/dev/null || true
  done
  chmod -R u+rwx -- "$root" 2>/dev/null || true
  rm -rf -- "$root"
}
trap cleanup EXIT

three_days_ago=$(($(date +%s) - 3 * 86400))

# The tag cargo writes into every target directory it creates.
cargo_tag='Signature: 8a477f597d28d172789f06886806bc55
# This file is a cache directory tag created by cargo.
# For information about cache directory tags see https://bford.info/cachedir/'

fail() {
  printf 'FAIL %s: %s\n' "$case_name" "$*"
  failures=$((failures + 1))
}

# Starts a case: a fresh work directory, named for the case, in $work, and a
# state directory for it in $state.
begin() {
  case_name=$1
  failures_before=$failures
  work=$root/$case_name/work
  state=$root/$case_name/state
  mkdir -p -- "$work"
}

# A cargo target directory with one built profile.
make_target() {
  local dir=$1
  mkdir -p -- "$dir/debug/deps" "$dir/debug/.fingerprint"
  printf '%s\n' "$cargo_tag" >"$dir/CACHEDIR.TAG"
  printf 'rlib\n' >"$dir/debug/deps/libcrate.rlib"
}

# Sets the mtime of everything under a path, the path included.
age() {
  find "$1" -exec touch -h -d "@$2" {} +
}

# Runs the prune against $work and $state with a floor nothing here goes below,
# and keeps its output in $output and its exit status in $status.
run_prune() {
  status=0
  output=$("$prune" --work-dir "$work" --state-dir "$state" --free-floor-gib 1 "$@" 2>&1) || status=$?
}

# Starts a process with the given working directory that runs until the tests
# end, and waits until /proc shows it there.
hold_cwd() {
  local dir=$1 pid
  (cd -- "$dir" && exec sleep 600) &
  pid=$!
  holders+=("$pid")
  until [[ $(readlink -- "/proc/$pid/cwd" 2>/dev/null) == "$dir" ]]; do
    sleep 0.1
  done
}

# Starts a binary that lives under a directory, with its working directory
# elsewhere, so the mapping of its executable is the only thing holding the
# directory, and waits until /proc shows the mapping. The copy keeps sleep as its
# argv[0] because coreutils may be one binary that dispatches on that name.
hold_mapped() {
  local binary=$1 cwd=$2 pid
  cp -L -- "$(command -v sleep)" "$binary"
  chmod u+x -- "$binary"
  (cd -- "$cwd" && exec -a sleep "$binary" 600) &
  pid=$!
  holders+=("$pid")
  until grep -qsF -- "$binary" "/proc/$pid/maps"; do
    sleep 0.1
  done
}

expect_status() {
  [[ $status == "$1" ]] || fail "exit status $status, expected $1; output:"$'\n'"$output"
}

expect_present() {
  [[ -e $1 ]] || fail "$1 is gone"
}

expect_absent() {
  [[ ! -e $1 ]] || fail "$1 is still there"
}

expect_log() {
  grep -qF -- "$1" <<<"$output" || fail "no log line containing '$1'; output:"$'\n'"$output"
}

expect_no_marker() {
  local marker
  for marker in "$work"/*.pruning.*; do
    if [[ -e $marker ]]; then
      fail "$marker is left behind"
    fi
  done
}

finish() {
  if (( failures == failures_before )); then
    printf 'ok   %s\n' "$case_name"
  fi
}

case_idle_target_removed() {
  begin idle-target-removed
  mkdir -p -- "$work/crew/src"
  printf 'fn main() {}\n' >"$work/crew/src/main.rs"
  make_target "$work/crew/target"
  age "$work/crew" "$three_days_ago"
  run_prune --full
  expect_status 0
  expect_absent "$work/crew/target"
  expect_present "$work/crew/src/main.rs"
  expect_log "removed (rule idle"
  finish
}

case_recent_target_kept() {
  begin recent-target-kept
  make_target "$work/crew/target"
  run_prune --full
  expect_status 0
  expect_present "$work/crew/target/debug/deps/libcrate.rlib"
  finish
}

case_unmarked_directory_kept() {
  begin unmarked-directory-kept
  mkdir -p -- "$work/crew/target/release"
  printf 'packaging\n' >"$work/crew/target/release/build.sh"
  age "$work/crew" "$three_days_ago"
  run_prune --full
  expect_status 0
  expect_present "$work/crew/target/release/build.sh"
  finish
}

case_working_directory_kept() {
  begin working-directory-kept
  make_target "$work/crew/target"
  age "$work/crew" "$three_days_ago"
  hold_cwd "$work/crew/target/debug"
  run_prune --full
  expect_status 0
  expect_present "$work/crew/target/debug/deps/libcrate.rlib"
  expect_log "has it as its working directory"
  finish
}

case_mapped_binary_kept() {
  begin mapped-binary-kept
  make_target "$work/crew/target"
  mkdir -p -- "$root/$case_name/elsewhere"
  hold_mapped "$work/crew/target/debug/deps/crate-test" "$root/$case_name/elsewhere"
  age "$work/crew" "$three_days_ago"
  run_prune --full
  expect_status 0
  expect_present "$work/crew/target/debug/deps/crate-test"
  expect_log "has it mapped"
  finish
}

case_failed_delete_skipped() {
  local leftover
  begin failed-delete-skipped
  make_target "$work/stuck/target"
  mkdir -p -- "$work/stuck/target/debug/deps/locked"
  printf 'owned\n' >"$work/stuck/target/debug/deps/locked/file"
  make_target "$work/other/target"
  age "$work" "$three_days_ago"
  chmod a-w -- "$work/stuck/target/debug/deps/locked"
  run_prune --full
  expect_status 0
  expect_log "kept (the delete failed"
  expect_log "finished: 1 target directories"
  expect_absent "$work/other/target"
  expect_present "$state/scan"
  for leftover in "$work"/stuck/target.pruning.*; do
    expect_present "$leftover/debug/deps/locked/file"
  done
  # A later run finds the marker the failed delete left, once that has been
  # idle as long, fails on it the same way, and still gets to the end.
  age "$work" "$three_days_ago"
  rm -f -- "$state/scan"
  run_prune --full
  expect_status 0
  expect_log "kept (the delete failed"
  expect_log "finished: 0 target directories"
  expect_present "$state/scan"
  finish
}

case_failed_rename_skipped() {
  begin failed-rename-skipped
  make_target "$work/crew/target"
  make_target "$work/other/target"
  age "$work" "$three_days_ago"
  chmod a-w -- "$work/crew"
  run_prune --full
  expect_status 0
  expect_log "kept (renaming it for the delete failed)"
  expect_present "$work/crew/target/debug/deps/libcrate.rlib"
  expect_absent "$work/other/target"
  finish
}

case_foreign_cache_tag_kept() {
  begin foreign-cache-tag-kept
  mkdir -p -- "$work/venv/lib/python3.13/site-packages"
  printf 'Signature: 8a477f597d28d172789f06886806bc55\n# This file is a cache directory tag created by uv.\n' >"$work/venv/CACHEDIR.TAG"
  printf 'home = /usr/bin\n' >"$work/venv/pyvenv.cfg"
  mkdir -p -- "$work/crew/target/v"
  printf 'Signature: 8a477f597d28d172789f06886806bc55\n# This file is a cache directory tag created by pytest.\n' >"$work/crew/target/CACHEDIR.TAG"
  age "$work" "$three_days_ago"
  run_prune --full
  expect_status 0
  expect_present "$work/venv/pyvenv.cfg"
  expect_present "$work/crew/target/CACHEDIR.TAG"
  expect_log "found 0 target directories"
  finish
}

case_symlinked_cargo_tag_kept() {
  begin symlinked-cargo-tag-kept
  mkdir -p -- "$root/$case_name/elsewhere" "$work/crew/target"
  printf '%s\n' "$cargo_tag" >"$root/$case_name/elsewhere/CACHEDIR.TAG"
  ln -s -- "$root/$case_name/elsewhere/CACHEDIR.TAG" "$work/crew/target/CACHEDIR.TAG"
  printf 'keep\n' >"$work/crew/target/keep.txt"
  age "$work" "$three_days_ago"
  run_prune --full
  expect_status 0
  expect_present "$work/crew/target/keep.txt"
  expect_log "found 0 target directories"
  finish
}

case_direct_target_keeps_crew_files() {
  local dir
  begin direct-target-keeps-crew-files
  dir=$work/crew-target
  make_target "$dir"
  printf '{}\n' >"$dir/.rustc_info.json"
  mkdir -p -- "$dir/ci/deps" "$dir/ci/.fingerprint" \
    "$dir/x86_64-unknown-linux-gnu/release/deps" "$dir/x86_64-unknown-linux-gnu/release/.fingerprint" \
    "$dir/tmp" "$dir/scripts/deps"
  printf 'notes\n' >"$dir/NOTES.md"
  printf 'run\n' >"$dir/scripts/deps/run.sh"
  age "$work" "$three_days_ago"
  run_prune --full
  expect_status 0
  expect_log "removed (rule idle"
  expect_absent "$dir/debug"
  expect_absent "$dir/ci"
  expect_absent "$dir/x86_64-unknown-linux-gnu"
  expect_absent "$dir/.rustc_info.json"
  expect_absent "$dir/CACHEDIR.TAG"
  expect_present "$dir/NOTES.md"
  expect_present "$dir/scripts/deps/run.sh"
  expect_present "$dir/tmp"
  expect_no_marker
  finish
}

case_direct_target_failed_move_kept() {
  begin direct-target-failed-move-kept
  make_target "$work/crew-target"
  make_target "$work/other/target"
  age "$work" "$three_days_ago"
  chmod a-w -- "$work/crew-target"
  run_prune --full
  expect_status 0
  expect_log "kept (moving cargo's output out for the delete failed"
  expect_present "$work/crew-target/debug/deps/libcrate.rlib"
  expect_absent "$work/other/target"
  expect_no_marker
  finish
}

case_direct_target_emptied_removed() {
  begin direct-target-emptied-removed
  make_target "$work/crew-target"
  age "$work" "$three_days_ago"
  run_prune --full
  expect_status 0
  expect_absent "$work/crew-target"
  finish
}

case_budget_skips_kept_directory() {
  local now
  begin budget-skips-kept-directory
  now=$(date +%s)
  make_target "$work/crew/target"
  make_target "$work/crew-target"
  make_target "$work/CREW/target"
  fallocate -l 400MiB -- "$work/crew/target/debug/deps/libbig.rlib"
  fallocate -l 400MiB -- "$work/crew-target/debug/deps/libbig.rlib"
  fallocate -l 400MiB -- "$work/CREW/target/debug/deps/libbig.rlib"
  age "$work/crew" $((now - 3 * 86400))
  age "$work/crew-target" $((now - 2 * 86400))
  age "$work/CREW" $((now - 86400))
  hold_cwd "$work/crew/target/debug"
  run_prune --full --crew-budget-gib 1 --idle-hours 1000
  expect_status 0
  expect_log "kept (in use) $work/crew/target"
  expect_log "removed (rule budget"
  expect_present "$work/crew/target/debug/deps/libbig.rlib"
  expect_absent "$work/crew-target"
  expect_present "$work/CREW/target/debug/deps/libbig.rlib"
  finish
}

case_marker_name_alone_kept() {
  local dir
  begin marker-name-alone-kept
  mkdir -p -- "$work/notes.pruning.2026.11"
  printf 'plan\n' >"$work/notes.pruning.2026.11/plan.md"
  dir=$work/crew.pruning.1700000000.42
  make_target "$dir"
  printf 'notes\n' >"$dir/NOTES.md"
  age "$work" "$three_days_ago"
  run_prune --full
  expect_status 0
  expect_present "$work/notes.pruning.2026.11/plan.md"
  expect_absent "$dir/debug"
  expect_present "$dir/NOTES.md"
  finish
}

case_interrupted_staging_removed() {
  local marker
  begin interrupted-staging-removed
  make_target "$work/crew-target"
  printf 'notes\n' >"$work/crew-target/NOTES.md"
  rm -rf -- "$work/crew-target/debug"
  # What a run cut short partway through staging leaves: a recorded marked
  # directory holding a profile, with the tag still behind in the entry.
  marker=$work/crew-target.pruning.1700000000.42
  mkdir -p -- "$marker/ci/deps" "$marker/ci/.fingerprint" "$state"
  printf '%s\0' "$marker" >"$state/staged"
  age "$work" "$three_days_ago"
  run_prune --full
  expect_status 0
  expect_absent "$marker"
  expect_present "$work/crew-target/NOTES.md"
  if grep -qzxF -- "$marker" "$state/staged"; then
    fail "$marker is still recorded in $state/staged"
  fi
  finish
}

case_deleting_needs_state_dir() {
  begin deleting-needs-state-dir
  make_target "$work/crew/target"
  age "$work" "$three_days_ago"
  status=0
  output=$("$prune" --work-dir "$work" --free-floor-gib 1 --full 2>&1) || status=$?
  expect_status 2
  expect_present "$work/crew/target/debug/deps/libcrate.rlib"
  finish
}

case_idle_target_removed
case_recent_target_kept
case_unmarked_directory_kept
case_working_directory_kept
case_mapped_binary_kept
case_failed_delete_skipped
case_failed_rename_skipped
case_foreign_cache_tag_kept
case_symlinked_cargo_tag_kept
case_direct_target_keeps_crew_files
case_direct_target_emptied_removed
case_direct_target_failed_move_kept
case_budget_skips_kept_directory
case_marker_name_alone_kept
case_interrupted_staging_removed
case_deleting_needs_state_dir

if (( failures )); then
  printf '%s failed\n' "$failures"
  exit 1
fi
printf 'all cases passed\n'
