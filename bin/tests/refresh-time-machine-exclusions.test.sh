#!/usr/bin/env bash
# Black-box tests for bin/refresh-time-machine-exclusions.sh.
#
# SAFETY: every run happens inside a sandbox $HOME with stub `tmutil` and
# `sudo` first on PATH. The stubs only append their argv to a log file, so no
# real Time Machine exclusion is ever added or removed and no real sudo runs.
# setup_sandbox aborts the whole suite if either name still resolves outside
# the sandbox.
#
# Run: bash bin/tests/refresh-time-machine-exclusions.test.sh

set -uo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
SCRIPT="$REPO_ROOT/bin/refresh-time-machine-exclusions.sh"
REAL_PATH=$PATH

PASS=0
FAIL=0

assert_contains() {
  local haystack=$1 needle=$2 label=$3
  if [[ "$haystack" == *"$needle"* ]]; then
    PASS=$((PASS + 1))
    echo "  ok $label"
  else
    FAIL=$((FAIL + 1))
    echo "  FAIL $label"
    echo "    expected to contain: $needle"
    echo "    got: $haystack"
  fi
}

assert_not_contains() {
  local haystack=$1 needle=$2 label=$3
  if [[ "$haystack" != *"$needle"* ]]; then
    PASS=$((PASS + 1))
    echo "  ok $label"
  else
    FAIL=$((FAIL + 1))
    echo "  FAIL $label"
    echo "    expected NOT to contain: $needle"
    echo "    got: $haystack"
  fi
}

assert_nonzero() {
  local got=$1 label=$2
  if [[ "$got" != "0" ]]; then
    PASS=$((PASS + 1))
    echo "  ok $label"
  else
    FAIL=$((FAIL + 1))
    echo "  FAIL $label"
    echo "    expected a non-zero exit status, got 0"
  fi
}

assert_eq() {
  local got=$1 want=$2 label=$3
  if [[ "$got" == "$want" ]]; then
    PASS=$((PASS + 1))
    echo "  ok $label"
  else
    FAIL=$((FAIL + 1))
    echo "  FAIL $label"
    echo "    expected: $want"
    echo "    got:      $got"
  fi
}

# Sandbox $HOME + stub tmutil/sudo on PATH.
#   $CALL_LOG       every stub invocation, one per line, args shell-quoted so
#                   that accidental word splitting is visible
#   $EXCLUDED_LIST  paths tmutil reports as already excluded (grows on add)
#   $FAIL_ADD       if a path is listed here, addexclusion fails for it
setup_sandbox() {
  SANDBOX=$(mktemp -d)
  export HOME="$SANDBOX/home"
  mkdir -p "$HOME"

  export CALL_LOG="$SANDBOX/calls.log"
  export EXCLUDED_LIST="$SANDBOX/excluded.txt"
  export FAIL_ADD="$SANDBOX/fail-add.txt"
  : >"$CALL_LOG"
  : >"$EXCLUDED_LIST"
  : >"$FAIL_ADD"

  mkdir -p "$SANDBOX/bin"

  cat >"$SANDBOX/bin/tmutil" <<'STUB'
#!/usr/bin/env bash
{ printf 'tmutil'; printf ' %q' "$@"; printf '\n'; } >>"$CALL_LOG"
case "$1" in
  isexcluded)
    shift
    if grep -Fxq "$1" "$EXCLUDED_LIST"; then
      echo "[Excluded]    $1"
    else
      echo "[Included]    $1"
    fi
    ;;
  addexclusion)
    path=${*: -1}
    if grep -Fxq "$path" "$FAIL_ADD"; then
      echo "tmutil: unable to modify exclusion: $path" >&2
      exit 1
    fi
    echo "$path" >>"$EXCLUDED_LIST"
    ;;
  *)
    echo "tmutil: unexpected subcommand: $1" >&2
    exit 64
    ;;
esac
exit 0
STUB

  cat >"$SANDBOX/bin/sudo" <<'STUB'
#!/usr/bin/env bash
{ printf 'sudo'; printf ' %q' "$@"; printf '\n'; } >>"$CALL_LOG"
while [ $# -gt 0 ]; do
  case "$1" in
    -A | -n | -S) shift ;;
    *) break ;;
  esac
done
exec "$@"
STUB

  chmod +x "$SANDBOX/bin/tmutil" "$SANDBOX/bin/sudo"
  export PATH="$SANDBOX/bin:$REAL_PATH"

  local resolved
  for resolved in "$(command -v tmutil)" "$(command -v sudo)"; do
    case "$resolved" in
      "$SANDBOX/bin/"*) ;;
      *)
        echo "ABORT: harness escape -- '$resolved' is outside the sandbox" >&2
        exit 99
        ;;
    esac
  done
}

teardown_sandbox() {
  export PATH=$REAL_PATH
  rm -rf "$SANDBOX"
}

run_script() {
  OUT=$(bash "$SCRIPT" 2>&1)
  RC=$?
  LOG=$(cat "$CALL_LOG")
  # sandbox $HOME is a fresh mktemp path every run; fold it back to ~ so
  # output can be compared as a stable snapshot
  REPORT=$(printf '%s' "$OUT" | sed "s|$HOME|~|g")
}

echo "refresh-time-machine-exclusions"

echo "test: excludes the tool-cache dirs that exist, ignores the ones that do not"
setup_sandbox
mkdir -p "$HOME/.npm"
run_script
assert_contains "$LOG" "tmutil addexclusion -p $HOME/.npm" "adds ~/.npm"
assert_not_contains "$LOG" "$HOME/.cache" "never touches ~/.cache, which is absent"
assert_not_contains "$LOG" "$HOME/go/pkg/mod" "never touches ~/go/pkg/mod, which is absent"
assert_eq "$REPORT" "$(printf '  + ~/.npm\nTime Machine exclusions: 1 added, 0 already present, 0 failed')" \
  "reports the one exclusion, and a missing ~/src is not an error"
assert_eq "$RC" "0" "exits 0"
teardown_sandbox

echo "test: a machine with none of these dirs is a clean no-op"
setup_sandbox
run_script
assert_eq "$LOG" "" "runs no tmutil commands at all"
assert_eq "$REPORT" "Time Machine exclusions: 0 added, 0 already present, 0 failed" \
  "reports an empty run"
assert_eq "$RC" "0" "exits 0"
teardown_sandbox

echo "test: a second run adds nothing (idempotent)"
setup_sandbox
mkdir -p "$HOME/.npm" "$HOME/.cache" "$HOME/src/web/node_modules"
run_script
assert_contains "$LOG" "tmutil addexclusion -p $HOME/.npm" "first run adds ~/.npm"
assert_contains "$LOG" "tmutil addexclusion -p $HOME/src/web/node_modules" "first run adds the scanned node_modules"
: >"$CALL_LOG"
run_script
assert_not_contains "$LOG" "addexclusion" "second run adds nothing"
assert_contains "$LOG" "tmutil isexcluded $HOME/.npm" "second run still checks ~/.npm"
assert_eq "$REPORT" "Time Machine exclusions: 0 added, 3 already present, 0 failed" \
  "second run reports all three as already present"
assert_eq "$RC" "0" "exits 0"
teardown_sandbox

echo "test: handles a tool-cache path containing spaces as one path"
setup_sandbox
mkdir -p "$HOME/Library/Application Support/Code/Cache"
run_script
assert_contains "$LOG" "tmutil isexcluded $HOME/Library/Application\\ Support/Code/Cache" \
  "checks the spaced path as a single argument"
assert_contains "$LOG" "tmutil addexclusion -p $HOME/Library/Application\\ Support/Code/Cache" \
  "excludes the spaced path as a single argument"
assert_eq "$REPORT" "$(printf '  + ~/Library/Application Support/Code/Cache\nTime Machine exclusions: 1 added, 0 already present, 0 failed')" \
  "reports the spaced path"
assert_eq "$RC" "0" "exits 0"
teardown_sandbox

echo "test: excludes dependency/build dirs found under ~/src"
setup_sandbox
mkdir -p "$HOME/src/web/node_modules" "$HOME/src/web/.next" "$HOME/src/web/src/components"
mkdir -p "$HOME/src/api/target" "$HOME/src/api/build" "$HOME/src/py/.venv" "$HOME/src/py/venv"
mkdir -p "$HOME/src/nested/deep/pkg/dist" "$HOME/src/ios/DerivedData"
mkdir -p "$HOME/src/web/docs" "$HOME/src/notes"
mkdir -p "$HOME/src/my project/node_modules"
run_script
assert_contains "$LOG" "tmutil addexclusion -p $HOME/src/web/node_modules" "excludes node_modules"
assert_contains "$LOG" "tmutil addexclusion -p $HOME/src/web/.next" "excludes .next"
assert_contains "$LOG" "tmutil addexclusion -p $HOME/src/api/target" "excludes target"
assert_contains "$LOG" "tmutil addexclusion -p $HOME/src/api/build" "excludes build"
assert_contains "$LOG" "tmutil addexclusion -p $HOME/src/py/.venv" "excludes .venv"
assert_contains "$LOG" "tmutil addexclusion -p $HOME/src/py/venv" "excludes venv"
assert_contains "$LOG" "tmutil addexclusion -p $HOME/src/nested/deep/pkg/dist" "excludes a deeply nested dist"
assert_contains "$LOG" "tmutil addexclusion -p $HOME/src/ios/DerivedData" "excludes DerivedData"
assert_contains "$LOG" "tmutil addexclusion -p $HOME/src/my\\ project/node_modules" \
  "excludes a scanned path containing spaces as a single path"
assert_not_contains "$LOG" "$HOME/src/web/src" "leaves an ordinary source dir alone"
assert_not_contains "$LOG" "$HOME/src/web/docs" "leaves an ordinary docs dir alone"
assert_not_contains "$LOG" "$HOME/src/notes" "leaves an unrelated project dir alone"
assert_eq "$RC" "0" "exits 0"
teardown_sandbox

echo "test: does not descend into a dir it already excluded"
setup_sandbox
mkdir -p "$HOME/src/web/node_modules/pkg/node_modules"
mkdir -p "$HOME/src/web/node_modules/pkg/dist"
run_script
assert_contains "$LOG" "tmutil addexclusion -p $HOME/src/web/node_modules" "excludes the top-level node_modules"
assert_not_contains "$LOG" "$HOME/src/web/node_modules/pkg" "does not also exclude nested matches inside it"
assert_eq "$REPORT" "$(printf '  + ~/src/web/node_modules\nTime Machine exclusions: 1 added, 0 already present, 0 failed')" \
  "reports exactly one exclusion"
assert_eq "$RC" "0" "exits 0"
teardown_sandbox

echo "test: an exclusion that tmutil rejects is reported as failed and fails the run"
setup_sandbox
mkdir -p "$HOME/.npm" "$HOME/.cache"
echo "$HOME/.cache" >>"$FAIL_ADD"
run_script
assert_contains "$LOG" "tmutil addexclusion -p $HOME/.npm" "the healthy path is still excluded"
# shellcheck disable=SC2088 # literal ~, REPORT has $HOME folded back to ~
assert_contains "$REPORT" "~/.cache" "names the path that failed"
assert_contains "$REPORT" "1 added, 0 already present, 1 failed" "summary counts one added and one failed"
assert_nonzero "$RC" "exits non-zero"
teardown_sandbox

echo "test: an unreadable dir under ~/src fails the run but the rest is still excluded"
setup_sandbox
mkdir -p "$HOME/src/web/node_modules" "$HOME/src/locked/inner/dist"
chmod 000 "$HOME/src/locked"
run_script
chmod 755 "$HOME/src/locked"
assert_contains "$LOG" "tmutil addexclusion -p $HOME/src/web/node_modules" "still excludes what it could read"
# shellcheck disable=SC2088 # literal ~, REPORT has $HOME folded back to ~
assert_contains "$REPORT" "! errors while scanning ~/src" "reports the partial scan failure"
# shellcheck disable=SC2088
assert_contains "$REPORT" "+ ~/src/web/node_modules" "still reports what it could exclude"
assert_contains "$REPORT" "1 added, 0 already present, 1 failed" "counts the scan error as a failure"
assert_nonzero "$RC" "exits non-zero"
teardown_sandbox

echo "test: adds run through sudo -A, reads do not"
setup_sandbox
mkdir -p "$HOME/.npm"
run_script
assert_contains "$LOG" "sudo -A tmutil addexclusion -p $HOME/.npm" "elevates the add with the askpass helper"
assert_not_contains "$LOG" "sudo -A tmutil isexcluded" "reads the current state without sudo"
teardown_sandbox

# The fixed list is the whole point of the script: a dir silently dropped from
# it is dev-tool bloat silently landing in backups again. Compared as a sorted
# set, since the order the list is walked in is not part of the contract.
echo "test: excludes every tool-cache dir it claims to cover"
setup_sandbox
TOOL_CACHE_DIRS=(
  ".bun/install/cache"
  ".cache"
  ".colima"
  ".gradle"
  ".npm"
  ".yarn"
  "go/pkg/mod"
  "Library/Application Support/Code/Cache"
  "Library/Application Support/Code/CachedData"
  "Library/Application Support/Cursor/CachedData"
  "Library/Application Support/Cursor/CachedExtensionVSIXs"
  "Library/Application Support/Cursor/Partitions"
  "Library/Application Support/Cursor/logs"
  "Library/Developer/CoreSimulator"
  "Library/Developer/Xcode/DerivedData"
  "Library/pnpm/store"
)
for dir in "${TOOL_CACHE_DIRS[@]}"; do
  mkdir -p "$HOME/$dir"
done
run_script
assert_eq \
  "$(printf '%s\n' "$REPORT" | grep '^  + ' | LC_ALL=C sort)" \
  "$(printf '  + ~/%s\n' "${TOOL_CACHE_DIRS[@]}" | LC_ALL=C sort)" \
  "excludes every documented tool-cache dir, and nothing else"
assert_contains "$REPORT" "${#TOOL_CACHE_DIRS[@]} added, 0 already present, 0 failed" \
  "counts every one of them"
assert_eq "$RC" "0" "exits 0"
teardown_sandbox

echo
echo "passed: $PASS  failed: $FAIL"
[ "$FAIL" -eq 0 ]
