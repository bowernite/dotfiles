#!/bin/zsh
set -euo pipefail

CMUX_GHOSTTY_CONFIG="$HOME/Library/Application Support/com.cmuxterm.app/config.ghostty"
CMUX_BIN="/Applications/cmux.app/Contents/Resources/bin/cmux"
LIGHT_THEME="Modus Operandi"
DARK_THEME="Modus Vivendi Tinted"
LOGGER_TAG="com.user.set-cmux-terminal-theme"
TRIGGER="${TRIGGER:-manual}"

log() {
  echo "$1"
  logger -t "$LOGGER_TAG" "$1"
}

read_dark_mode_from_defaults() {
  if defaults read NSGlobalDomain AppleInterfaceStyle 2>/dev/null | grep -q Dark; then
    echo "true"
  else
    echo "false"
  fi
}

read_dark_mode_from_osascript() {
  local err mode osascript_status
  err=$(mktemp)
  mode=$(osascript -e 'tell application "System Events" to tell appearance preferences to get dark mode' 2>"$err")
  osascript_status=$?
  if [[ $osascript_status -ne 0 ]]; then
    log "osascript failed trigger=$TRIGGER exit=$osascript_status error=$(tr '\n' ' ' <"$err")"
    rm -f "$err"
    return 1
  fi
  rm -f "$err"
  echo "$mode"
}

read_dark_mode() {
  local attempt mode
  for attempt in 1 2 3; do
    if mode=$(read_dark_mode_from_osascript); then
      echo "$mode"
      return 0
    fi
    if [[ "$TRIGGER" == wake || "$TRIGGER" == unlock ]]; then
      log "retrying dark mode read trigger=$TRIGGER attempt=$attempt"
      sleep 1
    else
      break
    fi
  done

  mode=$(read_dark_mode_from_defaults)
  log "using defaults fallback trigger=$TRIGGER darkMode=$mode"
  echo "$mode"
}

MODE=$(read_dark_mode)
if [[ "$MODE" == "true" ]]; then
  THEME="$DARK_THEME"
else
  THEME="$LIGHT_THEME"
fi

log "applying theme trigger=$TRIGGER darkMode=$MODE theme=$THEME"

mkdir -p "$(dirname "$CMUX_GHOSTTY_CONFIG")"
cat >"$CMUX_GHOSTTY_CONFIG" <<EOF
# Managed by dotfiles set-cmux-terminal-theme.sh
# Unconditional theme avoids cmux split-theme resolution bug (manaflow-ai/cmux#4565)
theme = $THEME
EOF

if [[ "$MODE" == "true" ]]; then
  defaults write com.cmuxterm.app appearanceMode dark
else
  defaults write com.cmuxterm.app appearanceMode light
fi
defaults write com.cmuxterm.app sidebarMatchTerminalBackground -bool false

if [[ -x "$CMUX_BIN" ]]; then
  if "$CMUX_BIN" reload-config >/dev/null 2>&1; then
    log "cmux reload-config ok trigger=$TRIGGER theme=$THEME"
  else
    log "cmux reload-config failed trigger=$TRIGGER theme=$THEME"
    exit 1
  fi
else
  log "cmux reload-config skipped: binary missing trigger=$TRIGGER theme=$THEME"
fi
