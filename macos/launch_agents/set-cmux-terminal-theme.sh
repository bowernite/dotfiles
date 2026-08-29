#!/bin/zsh
set -euo pipefail

CMUX_GHOSTTY_CONFIG="$HOME/Library/Application Support/com.cmuxterm.app/config.ghostty"
CMUX_BIN="/Applications/cmux.app/Contents/Resources/bin/cmux"
LIGHT_THEME="Modus Operandi"
DARK_THEME="Modus Vivendi Tinted"

MODE=$(osascript -e 'tell application "System Events" to tell appearance preferences to get dark mode')
if [[ "$MODE" == "true" ]]; then
  THEME="$DARK_THEME"
else
  THEME="$LIGHT_THEME"
fi

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
  "$CMUX_BIN" reload-config >/dev/null 2>&1 || true
fi

logger -t "com.user.set-cmux-terminal-theme" "Set cmux terminal theme to $THEME"
