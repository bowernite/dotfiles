#!/bin/zsh

################################################################################
# Set the terminal theme based on the macOS appearance
################################################################################

# Get current macOS appearance
MODE=$(osascript -e 'tell application "System Events" to tell appearance preferences to get dark mode')

LIGHT_THEME="1984 Light"
DARK_THEME="GitHub Dark"

if [ "$MODE" = "true" ]; then
  /Applications/kitty.app/Contents/MacOS/kitten themes --reload-in=all "$DARK_THEME"
else
  /Applications/kitty.app/Contents/MacOS/kitten themes --reload-in=all "$LIGHT_THEME"
fi
