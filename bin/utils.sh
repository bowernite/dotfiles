#!/bin/sh

dotfiles_dir=~/src/personal/dotfiles

install_dotfile() {
  local name="$1"
  local from="$dotfiles_dir/$name"
  local to="$HOME/$name"

  if [ ! -e $to ]; then
    echo "Creating $to ..."
    ln -s $from $to
  fi
}

# test
##############################################################
# Pretty logger for bootstrapping only
##############################################################
log() {
    local separator="~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    printf "\n\n\n" 
    echo $separator
    echo "‍💻 $1"
    echo $separator
    echo
}