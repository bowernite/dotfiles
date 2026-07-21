#!/bin/zsh

# Replicates kitty's startup.conf for Ghostty using AppleScript (Ghostty 1.3+)
# Called via initial-command in Ghostty config — adds tabs to the already-open window.
# The first tab (where this runs) becomes the "slc servers" tab.

# Small delay to let the window fully initialize
sleep 0.5

osascript <<'APPLESCRIPT'
tell application "Ghostty"
    set win to front window

    -- Tab 2: ~/src/work/slc
    set cfg2 to new surface configuration
    set initial working directory of cfg2 to "/Users/brett/src/work/slc"
    new tab in win with configuration cfg2

    -- Tab 3: home
    set cfg3 to new surface configuration
    set initial working directory of cfg3 to "/Users/brett"
    new tab in win with configuration cfg3

    -- Switch back to first tab (slc servers)
    select tab (tab 1 of win)
end tell
APPLESCRIPT

# Run slc start in an interactive login shell (sources .zshrc so PATH is set),
# then drop back to a normal shell — same as kitty's `zsh -i -c "slc start; exec zsh"`
exec zsh -i -l -c "slc start; exec zsh"
