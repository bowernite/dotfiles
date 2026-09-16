#!/usr/bin/env bash

# Install every launch agent plist in this repo into ~/Library/LaunchAgents and
# (re)load it under launchd. Plists marked Disabled are installed but not loaded.
#
# Tracked plists hardcode /Users/brett/ (personal Mac). launchd does not expand
# $HOME, so this copies each plist and rewrites that prefix to $HOME.
#
# To unload one by hand: launchctl bootout gui/$UID/<label>

source ~/src/personal/dotfiles/bin/utils.sh

for src in "$dotfiles_dir"/macos/launch_agents/*.swift; do
  [ -e "$src" ] || continue
  dest="${src%.swift}"
  echo "Compiling $(basename "$src")"
  swiftc -O "$src" -o "$dest" || {
    echo "Failed to compile $src" >&2
    exit 1
  }
done

mkdir -p ~/Library/LaunchAgents

install_launch_agent_plist() {
  local src="$1"
  local dest="$2"
  chflags -h nouchg "$dest" 2>/dev/null || true
  rm -f "$dest"
  # Personal-Mac prefix only; no-op when $HOME is already /Users/brett.
  sed "s|/Users/brett/|${HOME}/|g" "$src" >"$dest"
}

for plist in "$dotfiles_dir"/macos/launch_agents/*.plist; do
  [ -e "$plist" ] || continue # with no plists the glob comes through unexpanded

  label=$(basename "$plist" .plist)
  dest="$HOME/Library/LaunchAgents/${label}.plist"
  install_launch_agent_plist "$plist" "$dest"

  launchctl bootout "gui/$UID/$label" 2>/dev/null
  # bootout returns before teardown finishes when the agent has a live process.
  for _ in $(seq 25); do
    launchctl print "gui/$UID/$label" >/dev/null 2>&1 || break
    sleep 0.2
  done

  if [ "$(plutil -extract Disabled raw -o - "$plist" 2>/dev/null)" = "true" ]; then
    echo "Skipping disabled launch agent: $label"
    continue
  fi

  program=$(plutil -extract ProgramArguments.0 raw -o - "$dest" 2>/dev/null || true)
  if [ -n "$program" ] && [ ! -e "$program" ]; then
    echo "Skipping launch agent with missing program: $label ($program)"
    continue
  fi

  launchctl bootstrap "gui/$UID" "$dest" ||
    echo "Failed to bootstrap launch agent: $label" >&2
done
