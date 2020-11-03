#!/bin/sh

fancy_echo() {
  local fmt="$1"; shift

  # shellcheck disable=SC2059
  printf "\n$fmt\n" "$@"
}

dotfiles_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

install_dotfile() {
  local name="$1"
  local from="$dotfiles_dir/$name"
  local to="$HOME/$name"

  if [ ! -e $to ]; then
    fancy_echo "Creating $to ..."
    ln -s $from $to
  fi
}

#######################################
# Pretty logger for bootstrapping only
#######################################
log() {
    local separator="~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    printf "\n\n\n" 
    echo $separator
    echo "👨‍💻 $1"
    echo $separator
    echo
}