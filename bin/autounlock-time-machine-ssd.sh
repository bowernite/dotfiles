#!/bin/bash
# Silently unlock the encrypted Time Machine SSD when it's attached but locked.
# APFSUserAgent often fails to use the keychain on this machine; this is the reliable path.

set -euo pipefail

UUID="53AEC47B-D288-4E75-8A10-247EFA74C897"
LOG="${HOME}/Library/Logs/autounlock-time-machine-ssd.log"

log() { printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >>"$LOG"; }

info=$(diskutil info "$UUID" 2>/dev/null) || exit 0

# Not present
echo "$info" | grep -q 'Volume UUID' || exit 0

# Already mounted / unlocked
if echo "$info" | grep -q 'Mounted: *Yes'; then
  exit 0
fi
if echo "$info" | grep -q 'Locked: *No'; then
  exit 0
fi

# Locked (or encrypted and not mounted)
pass=$(security find-generic-password -a "$UUID" -w 2>/dev/null) || {
  log "locked but no keychain password for $UUID"
  exit 1
}

if printf '%s' "$pass" | diskutil apfs unlockVolume "$UUID" -stdinpassphrase >>"$LOG" 2>&1; then
  log "unlocked $UUID"
else
  log "unlock failed for $UUID"
  exit 1
fi
