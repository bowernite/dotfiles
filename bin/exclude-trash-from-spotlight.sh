#!/bin/bash
# Keep ~/.Trash out of Spotlight (and Alfred, which uses Spotlight's index).
set -euo pipefail

TRASH="${HOME}/.Trash"
PLIST="/System/Volumes/Data/.Spotlight-V100/VolumeConfiguration.plist"
BUDDY="/usr/libexec/PlistBuddy"

ensure_never_index_marker() {
  mkdir -p "$TRASH"
  touch "$TRASH/.metadata_never_index"
}

purge_trash_from_spotlight_index() {
  ensure_never_index_marker
  /usr/bin/mdimport "$TRASH" 2>/dev/null || true
}

add_spotlight_privacy_exclusion() {
  if [[ ! -f "$PLIST" ]]; then
    echo "Missing $PLIST — cannot set Spotlight privacy." >&2
    exit 1
  fi

  if ! "$BUDDY" -c "Print :Exclusions" "$PLIST" &>/dev/null; then
    "$BUDDY" -c "Add :Exclusions array" "$PLIST"
  fi

  while IFS= read -r path; do
    [[ -z "$path" ]] && continue
    if [[ "$path" == "$TRASH" ]]; then
      echo "Spotlight privacy already includes $TRASH"
      return 0
    fi
  done < <("$BUDDY" -c "Print :Exclusions" "$PLIST" 2>/dev/null | sed '1d;$d' || true)

  "$BUDDY" -c "Add :Exclusions: string $TRASH" "$PLIST"
  echo "Added $TRASH to Spotlight privacy exclusions"
}

purge_trash_from_spotlight_index

if [[ "${1:-}" == "--configure-privacy" ]]; then
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    echo "Expected root for --configure-privacy." >&2
    exit 1
  fi
  add_spotlight_privacy_exclusion
  exit 0
fi

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  export SUDO_ASKPASS="${SUDO_ASKPASS:-$HOME/src/personal/dotfiles/bin/sudo_askpass.sh}"
  exec sudo -A "$0" --configure-privacy
fi

add_spotlight_privacy_exclusion
