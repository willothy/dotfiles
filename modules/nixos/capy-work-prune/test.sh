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

# Starts a case: a fresh work directory, named for the case, in $work.
begin() {
  case_name=$1
  failures_before=$failures
  work=$root/$case_name/work
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

# Runs the prune against $work with a floor nothing here goes below, and keeps
# its output in $output and its exit status in $status.
run_prune() {
  status=0
  output=$("$prune" --work-dir "$work" --free-floor-gib 1 "$@" 2>&1) || status=$?
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

case_idle_target_removed
case_recent_target_kept
case_unmarked_directory_kept
case_working_directory_kept

if (( failures )); then
  printf '%s failed\n' "$failures"
  exit 1
fi
printf 'all cases passed\n'
