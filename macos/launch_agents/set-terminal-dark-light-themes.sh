#!/bin/zsh

################################################################################
# Set the terminal theme based on the macOS appearance
################################################################################

echo "Setting terminal theme based on macOS appearance"
logger -t "com.user.set-terminal-dark-light-theme" "Setting terminal theme based on macOS appearance"

# Get current macOS appearance
MODE=$(osascript -e 'tell application "System Events" to tell appearance preferences to get dark mode')

# # Kitty themes
# LIGHT_THEME="Modus Operandi"
# DARK_THEME="Modus Vivendi Tinted"

if [ "$MODE" = "true" ]; then
  # /Applications/kitty.app/Contents/MacOS/kitten themes --reload-in=all "$DARK_THEME"
  CLAUDE_THEME="dark"
else
  # /Applications/kitty.app/Contents/MacOS/kitten themes --reload-in=all "$LIGHT_THEME"
  CLAUDE_THEME="light"
fi

# Update Claude Code theme
CLAUDE_JSON="$HOME/.claude.json"
if [ -f "$CLAUDE_JSON" ]; then
  jq --arg theme "$CLAUDE_THEME" '.theme = $theme' "$CLAUDE_JSON" > "$CLAUDE_JSON.tmp" && mv "$CLAUDE_JSON.tmp" "$CLAUDE_JSON"
  echo "Set Claude Code theme to $CLAUDE_THEME"
  logger -t "com.user.set-terminal-dark-light-theme" "Set Claude Code theme to $CLAUDE_THEME"
fi
