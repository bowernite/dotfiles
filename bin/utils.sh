#!/bin/sh

dotfiles_dir=~/src/personal/dotfiles

#######################################
# "Installs" a dotfile by symlinking it from this directory to $HOME.
#
# Arguments:
#   from_filename: The filename of the file to be symlinked in this directory
#   [to_filename]: The name of the target/the symlink to create
#######################################
install_dotfile() {
  local from_filename=$1
  local to_filename=$2

  # Default the new/to filename to the name of the file in this repo
  if [[ -z $to_filename ]]; then
    to_filename=$from_filename
  fi

  local from="$dotfiles_dir/$from_filename"
  local to="$HOME/$to_filename"

  if [ ! -e $to ]; then
    if [ -h $to ]; then
      echo "Symlink already exists for $to... Deleting"
      rm $to
    fi

    echo "Creating $to..."
    ln -s $from $to
  fi
}

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
