#!/usr/bin/env bash
# Black-box tests for setup/install-launch-agents.sh.
#
# Everything runs against a sandbox $HOME with a stubbed `launchctl` on PATH,
# so no real launch agent is ever touched.
#
# Run: bash setup/tests/install-launch-agents.test.sh

set -uo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)

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

assert_empty() {
  local haystack=$1 label=$2
  if [ -z "$haystack" ]; then
    PASS=$((PASS + 1))
    echo "  ok $label"
  else
    FAIL=$((FAIL + 1))
    echo "  FAIL $label"
    echo "    expected empty, got: $haystack"
  fi
}

assert_at_least() {
  local actual=$1 min=$2 label=$3
  if [ "$actual" -ge "$min" ]; then
    PASS=$((PASS + 1))
    echo "  ok $label"
  else
    FAIL=$((FAIL + 1))
    echo "  FAIL $label"
    echo "    expected at least $min, got $actual"
  fi
}

assert_at_most() {
  local actual=$1 max=$2 label=$3
  if [ "$actual" -le "$max" ]; then
    PASS=$((PASS + 1))
    echo "  ok $label"
  else
    FAIL=$((FAIL + 1))
    echo "  FAIL $label"
    echo "    expected at most $max, got $actual"
  fi
}

# A sandbox $HOME containing a copy of the repo (so install_dotfile's symlinks
# and launchctl calls land in the sandbox), plus a stub launchctl that logs its
# argv instead of talking to launchd.
#
# Stub knobs (env vars, read at call time):
#   STUB_PRINT_ALIVE_COUNT  `print` exits 0 this many times, then exits 1
#                           (simulates an agent whose teardown takes a while)
#   STUB_BOOTSTRAP_FAIL_LABEL  `bootstrap` of this label exits 1
setup_sandbox() {
  SANDBOX=$(mktemp -d)
  export HOME="$SANDBOX/home"
  DOTFILES="$HOME/src/personal/dotfiles"
  mkdir -p "$DOTFILES/macos/launch_agents"
  ln -s "$REPO_ROOT/bin" "$DOTFILES/bin"
  ln -s "$REPO_ROOT/setup" "$DOTFILES/setup"

  mkdir -p "$SANDBOX/bin"
  export CALL_LOG="$SANDBOX/calls.log"
  : >"$CALL_LOG"
  export STUB_PRINT_ALIVE_COUNT=0
  export STUB_BOOTSTRAP_FAIL_LABEL="__none__"
  export STUB_STATE="$SANDBOX/print-calls"
  : >"$STUB_STATE"

  cat >"$SANDBOX/bin/launchctl" <<'STUB'
#!/usr/bin/env bash
echo "launchctl $*" >>"$CALL_LOG"

if [[ "$1" == "bootstrap" && "$*" == *"$STUB_BOOTSTRAP_FAIL_LABEL"* ]]; then
  echo "launchctl: stub bootstrap failure" >&2
  exit 1
fi

if [[ "$1" == "print" ]]; then
  seen=$(wc -l <"$STUB_STATE" | tr -d ' ')
  echo x >>"$STUB_STATE"
  if [ "$seen" -lt "$STUB_PRINT_ALIVE_COUNT" ]; then
    exit 0 # still running
  fi
  echo "Could not find service" >&2
  exit 113
fi

exit 0
STUB
  chmod +x "$SANDBOX/bin/launchctl"
  export PATH="$SANDBOX/bin:$PATH"

  # Refuse to run at all if the stub is not the launchctl we would reach --
  # a real bootout/bootstrap would tear down this machine's live agents.
  local resolved
  resolved=$(command -v launchctl)
  case "$resolved" in
    "$SANDBOX/bin/"*) ;;
    *)
      echo "ABORT: harness escape -- '$resolved' is outside the sandbox" >&2
      exit 99
      ;;
  esac
}

teardown_sandbox() {
  chflags -R nouchg "$SANDBOX" 2>/dev/null
  rm -rf "$SANDBOX"
}

# write_plist LABEL [Disabled]
write_plist() {
  local label=$1 disabled=${2:-}
  {
    cat <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$label</string>
PLIST
    if [ -n "$disabled" ]; then
      echo "  <key>Disabled</key><$disabled/>"
    fi
    cat <<'PLIST'
</dict>
</plist>
PLIST
  } >"$DOTFILES/macos/launch_agents/$label.plist"
}

# Runs the script under test. OUT/ERR hold its stdout/stderr, CALLS the
# launchctl call log.
run_install() {
  local out="$SANDBOX/stdout" err="$SANDBOX/stderr"
  bash "$DOTFILES/setup/install-launch-agents.sh" >"$out" 2>"$err"
  OUT=$(cat "$out")
  ERR=$(cat "$err")
  CALLS=$(cat "$CALL_LOG")
}

echo "install-launch-agents"

setup_sandbox
write_plist com.test.alpha
run_install
assert_contains "$(readlink "$HOME/Library/LaunchAgents/com.test.alpha.plist")" \
  "$DOTFILES/macos/launch_agents/com.test.alpha.plist" \
  "installs the plist into ~/Library/LaunchAgents as a symlink back to the repo"
assert_contains "$CALLS" "bootstrap gui/$UID $HOME/Library/LaunchAgents/com.test.alpha.plist" \
  "bootstraps the installed agent"
teardown_sandbox

# The real thing: install this repo's actual launch agents. Catches a malformed
# or unreadable plist, and proves the glob picks out plists from the scripts and
# binaries that live alongside them.
setup_sandbox
cp -R "$REPO_ROOT/macos/launch_agents/." "$DOTFILES/macos/launch_agents/"
run_install
UNLINKED=""
UNHANDLED=""
for plist in "$REPO_ROOT"/macos/launch_agents/*.plist; do
  label=$(basename "$plist" .plist)
  [ "$(readlink "$HOME/Library/LaunchAgents/$label.plist")" = \
    "$DOTFILES/macos/launch_agents/$label.plist" ] || UNLINKED="$UNLINKED $label"
  case "$CALLS$OUT" in
    *"bootstrap gui/$UID $HOME/Library/LaunchAgents/$label.plist"*) ;;
    *"disabled launch agent: $label"*) ;;
    *) UNHANDLED="$UNHANDLED $label" ;;
  esac
done
assert_empty "$UNLINKED" "links every real launch agent in the repo into ~/Library/LaunchAgents"
assert_empty "$UNHANDLED" "loads every real launch agent, or says it skipped a disabled one"
assert_empty "$(ls "$HOME/Library/LaunchAgents" | grep -v '\.plist$')" \
  "installs nothing but plists (the helper scripts and binaries stay put)"
assert_empty "$ERR" "installs the real launch agents without errors"
teardown_sandbox

# The agent's process outlives `bootout`, so the script has to poll until
# `launchctl print` stops finding it before it may bootstrap the new copy.
setup_sandbox
STUB_PRINT_ALIVE_COUNT=3
write_plist com.test.slow
run_install
assert_contains "$(uniq <<<"$CALLS")" "launchctl bootout gui/$UID/com.test.slow
launchctl print gui/$UID/com.test.slow
launchctl bootstrap gui/$UID $HOME/Library/LaunchAgents/com.test.slow.plist" \
  "boots the old agent out, then polls, then bootstraps the new copy"
assert_at_least "$(grep -c "launchctl print gui/$UID/com.test.slow" <<<"$CALLS")" 4 \
  "keeps polling while the old agent is still loaded"
teardown_sandbox

setup_sandbox
write_plist com.test.enabled
write_plist com.test.off true
run_install
assert_contains "$(ls "$HOME/Library/LaunchAgents")" "com.test.off.plist" \
  "installs a Disabled plist"
assert_not_contains "$CALLS" "bootstrap gui/$UID $HOME/Library/LaunchAgents/com.test.off.plist" \
  "never loads a Disabled agent"
assert_contains "$OUT" "disabled launch agent: com.test.off" \
  "says which agent was skipped for being disabled"
assert_contains "$CALLS" "bootout gui/$UID/com.test.off" \
  "still unloads a Disabled agent, so marking one disabled stops it"
assert_contains "$CALLS" "bootstrap gui/$UID $HOME/Library/LaunchAgents/com.test.enabled.plist" \
  "still loads the agents that are not disabled"
teardown_sandbox

setup_sandbox
write_plist com.test.on false
run_install
assert_contains "$CALLS" "bootstrap gui/$UID $HOME/Library/LaunchAgents/com.test.on.plist" \
  "loads an agent whose Disabled key is explicitly false"
assert_not_contains "$OUT" "disabled launch agent" \
  "does not call an explicitly-not-disabled agent disabled"
teardown_sandbox

setup_sandbox
STUB_BOOTSTRAP_FAIL_LABEL=com.test.broken
write_plist com.test.broken
write_plist com.test.zulu
run_install
assert_contains "$ERR" "com.test.broken" \
  "reports a failed load on stderr"
assert_contains "$CALLS" "bootstrap gui/$UID $HOME/Library/LaunchAgents/com.test.zulu.plist" \
  "carries on with the remaining agents after a failed load"
teardown_sandbox

# Someone dropped their own copy into ~/Library/LaunchAgents by hand before
# ever running setup.
setup_sandbox
write_plist com.test.handmade
mkdir -p "$HOME/Library/LaunchAgents"
printf 'a hand-written plist\n' >"$HOME/Library/LaunchAgents/com.test.handmade.plist"
run_install
assert_contains "$(readlink "$HOME/Library/LaunchAgents/com.test.handmade.plist")" \
  "$DOTFILES/macos/launch_agents/com.test.handmade.plist" \
  "replaces a hand-installed plist with the symlink to the repo"
assert_contains "$OUT" "exists and is not a symlink" \
  "warns before removing the hand-installed file"
assert_contains "$CALLS" "bootstrap gui/$UID $HOME/Library/LaunchAgents/com.test.handmade.plist" \
  "loads the agent it took over"
teardown_sandbox

# install_dotfile locks its symlinks with `chflags -h uchg`, so a re-run has to
# cope with a file it is not allowed to overwrite in place.
setup_sandbox
write_plist com.test.repeat
run_install
: >"$CALL_LOG"
run_install
assert_empty "$ERR" \
  "a repeat run reports no errors"
assert_contains "$(readlink "$HOME/Library/LaunchAgents/com.test.repeat.plist")" \
  "$DOTFILES/macos/launch_agents/com.test.repeat.plist" \
  "a repeat run leaves the symlink pointing at the repo"
assert_contains "$CALLS" "bootstrap gui/$UID $HOME/Library/LaunchAgents/com.test.repeat.plist" \
  "a repeat run reloads the agent"
teardown_sandbox

# An agent that never goes away must not wedge setup; the wait is capped and the
# run carries on. (This is the one slow test: the cap is ~5s.)
setup_sandbox
STUB_PRINT_ALIVE_COUNT=9999
write_plist com.test.stuck
STARTED=$SECONDS
run_install
ELAPSED=$((SECONDS - STARTED))
assert_contains "$CALLS" "bootstrap gui/$UID $HOME/Library/LaunchAgents/com.test.stuck.plist" \
  "gives up waiting on an agent that never tears down, and carries on"
assert_at_most "$ELAPSED" 20 \
  "an agent that never tears down does not wedge the run (${ELAPSED}s)"
teardown_sandbox

echo
echo "passed: $PASS  failed: $FAIL"
[ "$FAIL" -eq 0 ]
