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

  # Check if source file exists
  if [[ ! -e "$from" ]]; then
    echo "Source file $from does not exist. Skipping symlink creation."
    return 1
  fi

  # Remove existing symlink if it exists (whether broken or working)
  if [[ -L "$to" ]]; then
    echo "Removing existing symlink: $to"
    rm "$to"
  fi
  
  # Remove existing file/directory if it exists and is not a symlink
  if [[ -e "$to" ]]; then
    echo "File/directory already exists at $to. Removing to create symlink."
    rm -rf "$to"
  fi

  echo "Creating symlink: $to -> $from"
  ln -s "$from" "$to"
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
