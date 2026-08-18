#!/usr/bin/env bash

# Symlink every launch agent plist in this repo into ~/Library/LaunchAgents and
# (re)load it under launchd. Plists marked Disabled are installed but not loaded.
#
# To unload one by hand: launchctl bootout gui/$UID/<label>

source ~/src/personal/dotfiles/bin/utils.sh

mkdir -p ~/Library/LaunchAgents

for plist in "$dotfiles_dir"/macos/launch_agents/*.plist; do
  label=$(basename "$plist" .plist)
  install_dotfile "macos/launch_agents/${label}.plist" "Library/LaunchAgents/${label}.plist"

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

  launchctl bootstrap "gui/$UID" ~/Library/LaunchAgents/"${label}.plist" ||
    echo "Failed to bootstrap launch agent: $label" >&2
done
