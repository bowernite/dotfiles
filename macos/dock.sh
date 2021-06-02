#!/bin/sh

dockutil --no-restart --remove all
dockutil --no-restart --add "/System/Applications/Utilities/Terminal.app"
dockutil --no-restart --add "/Applications/Google Chrome.app"
dockutil --no-restart --add "/Applications/Visual Studio Code.app"
dockutil --no-restart --add "$HOME/Applications/Chrome Apps.localized/Trello.app"
dockutil --no-restart --add "/System/Applications/Notes.app"
dockutil --no-restart --add "/System/Applications/Messages.app"
dockutil --no-restart --add "/System/Applications/Reminders.app"
dockutil --no-restart --add "/System/Applications/Calendar.app"
dockutil --no-restart --add "/System/Applications/Music.app"
dockutil --no-restart --add "/Applications/Spotify.app"
dockutil --no-restart --add "/Applications/Alfred 4.app/Contents/Preferences/Alfred Preferences.app"
dockutil --no-restart --add "/System/Applications/System Preferences.app"

dockutil --add '~/Desktop' --view grid --display folder
dockutil --add '~/Documents' --view grid --display folder
dockutil --add '~/Downloads' --view grid --display folder

killall Dock
