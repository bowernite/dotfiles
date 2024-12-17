#!/bin/zsh

################################################################################
# Set the terminal theme based on the macOS appearance
################################################################################

echo "Setting terminal theme based on macOS appearance"
logger -t "com.user.set-terminal-dark-light-theme" "Setting terminal theme based on macOS appearance"

# Get current macOS appearance
MODE=$(osascript -e 'tell application "System Events" to tell appearance preferences to get dark mode')

# High contrast
LIGHT_THEME="Modus Operandi"

# High contrast (tinted is for navy blue background)
DARK_THEME="Modus Vivendi Tinted"
# DARK_THEME="GitHub Dark"

if [ "$MODE" = "true" ]; then
  /Applications/kitty.app/Contents/MacOS/kitten themes --reload-in=all "$DARK_THEME"
else
  /Applications/kitty.app/Contents/MacOS/kitten themes --reload-in=all "$LIGHT_THEME"
fi
