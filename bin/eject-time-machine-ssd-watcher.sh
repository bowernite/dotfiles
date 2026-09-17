#!/bin/bash
set -uo pipefail

VOLUME='Time Machine (SSD)'

eject_if_present() {
  diskutil info "$VOLUME" &>/dev/null || return 0
  diskutil eject "$VOLUME" 2>/dev/null || {
    whole="$(diskutil info "$VOLUME" | awk '/Part of Whole/ {print $4}')"
    [[ -n "$whole" ]] && diskutil unmountDisk force "$whole" 2>/dev/null || true
  }
}

eject_if_present

diskutil activity | while read -r line; do
  if [[ "$line" == *DiskAppeared* && "$line" == *"Time Machine (SSD)"* ]]; then
    eject_if_present
  fi
done
