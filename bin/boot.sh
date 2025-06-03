# WIP boot script
# launchctl plist file located at: $HOME/Library/LaunchAgents/com.user.loginscript.plist

# Created by following instructions here: https://stackoverflow.com/questions/6442364/running-script-upon-login-mac/13372744#13372744

# The `sleep`s are to prevent VS Code from opening them all in one Workspace together (one window instead of separately)
# -g makes it not go into the foreground, -j opens it hidden. Doesn't seem to work if the app is already open
# open -gj -a "Visual Studio Code" ~/Dropbox/wiki
# sleep 2
# open -gj -a "Visual Studio Code" ~/src/personal/dotfiles
# sleep 2
# open -gj -a "Visual Studio Code" ~/src/work/wonder-web
# sleep 2
# open -gj -a "Visual Studio Code" ~/src/personal/qmk_firmware

# open -gj -a "Trello"

# Optionally, hide/minimize any necessary windows, or all of them

#####################################################################
# Notes
#####################################################################

# For solving "Load failed 5: Input/output error" on BigSur
# https://developer.apple.com/forums/thread/665661#:~:text=i%20got%20the%20same%20issue%20after%20updating%20to%20bigsur.

# Alternative, using Automator and creating an "App": https://stackoverflow.com/questions/6442364/running-script-upon-login-mac
## This was way too many files than I wanted to store in my dotfiles, since a `.app` files is basically just a huge directory. So using a shell script with a LaunchAgents that runs it seemed a lot more lightweight and manageable
