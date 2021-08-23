# WIP boot script

# https://stackoverflow.com/questions/6442364/running-script-upon-login-mac
# Alternative: https://stackoverflow.com/questions/6442364/running-script-upon-login-mac/13372744#13372744

# The `sleep`s are to prevent VS Code from opening them all in one Workspace together (one window instead of separately)
open -a "Visual Studio Code" ~/Dropbox/wiki
sleep 0.5
open -a "Visual Studio Code" ~/src/personal/dotfiles
sleep 0.5
open -a "Visual Studio Code" ~/src/work/wonder-web
sleep 0.5
open -a "Visual Studio Code" ~/src/personal/qmk_firmware

open -a "Trello"

# Optionally, hide/minimize any necessary windows, or all of them