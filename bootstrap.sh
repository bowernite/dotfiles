#!/usr/bin/env bash
# 
# Bootstrap script for setting up a new OSX machine. From https://gist.github.com/codeinthehole/26b37efa67041e1307db
# 
# This should be idempotent so it can be run multiple times.
#
# Some apps don't have a cask and so still need to be installed by hand. These
# include:
#
# <none, for now>
#
# Notes:
#
# - If installing full Xcode, it's better to install that first from the app
#   store before running the bootstrap script. Otherwise, Homebrew can't access
#   the Xcode libraries as the agreement hasn't been accepted yet.
#
# Reading:
#
# - http://lapwinglabs.com/blog/hacker-guide-to-setting-up-your-mac
# - https://gist.github.com/MatthewMueller/e22d9840f9ea2fee4716
# - https://news.ycombinator.com/item?id=8402079
# - http://notes.jerzygangi.com/the-best-pgp-tutorial-for-mac-os-x-ever/

source ~/dotfiles/bin/utils.sh
cd $dotfiles_dir

clear
printf "Hi, $USER! 👋\n"
printf "Let's get you set up... 👨‍💻\n"
# For dramatic effect...
sleep 2s


##############################################################
# Symlinks
##############################################################
log "Symlinking appropriate files to the \$HOME directory ($HOME)"

install_dotfile ".zshrc"
install_dotfile ".gitconfig"
install_dotfile ".vimrc"
install_dotfile ".sandboxrc"

##############################################################
# Karabiner symlinking
##############################################################
log "Symlinking directory for Karabiner Elements"

kb_root_dir="$HOME/.config/karabiner"
kb_dotfiles_dir="$dotfiles_dir/karabiner"

[[ -d "$HOME/.config" ]] || mkdir "$HOME/.config"
[[ -d "${kb_root_dir}" ]] && rm -rf "${kb_root_dir}"
ln -sf "${kb_dotfiles_dir}" "${kb_root_dir}"
if [[ $? != 0 ]]; then
  echo "🚨 unable to link Karabiner Root directory to the dotfiles directory (${kb_root_dir} to ${kb_dotfiles_dir})"
  return 1
fi

# Goku symlinks
if [[ ! -h ~/.config/karabiner.edn ]]; then
  ln -s  "$dotfiles_dir/karabiner/karabiner.edn" ~/.config/karabiner.edn
fi
touch "$dotfiles_dir/karabiner/goku.log"
if [[ ! -h ~/Library/Logs/goku.log ]]; then
  ln -s "$dotfiles_dir/karabiner/goku.log" ~/Library/Logs/goku.log
fi

##############################################################
# Software installs (homebrew, npm/yarn)
##############################################################

source setup/brew.sh

# Might change this at some point if we go full yarn. Still, it _is_ nice to have npx for "use the local binary if it's there, otherwise use the global one". AFAIK, that doesn't exist with yarn. It's useful for our shell aliases for running prettier, jest, etc.
if ! command -v npx &> /dev/null; then
  npm i -g npx
fi

##############################################################
# macOS
##############################################################
# TODO: Store some kind of variable in a gitignored file. Use it to only run this command once for a whole machine (i.e. on a fresh macOS install)
log "Updating MacOS apps"
# Install latest macOS and Apple Apps (Safari, etc.)
# softwareupdate -i -a

source setup/macos.sh

##############################################################
# Filesystem setup
##############################################################

function touch_dir() {
  [[ -d $1 ]] || mkdir $1
}

touch_dir ~/src
touch_dir ~/src/clones
touch_dir ~/src/personal
touch_dir ~/src/work

##############################################################
# Clone git repos
#
# NEXT_MACHINE: See if this worked
##############################################################

function clone_repo() {
  local repo_name=$1
  if [[ ! -d $1 ]]; then
    git clone "https://github.com/babramczyk/$repo_name.git" "~/src/personal/$repo_name"
  fi
}

clone_repo base-project-config
clone_repo abramczyk.dev
clone_repo doofi

##############################################################
# Fin
##############################################################

log "All done. Have fun! 🚀"