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

source ~/dotfiles/bootstrap-helpers.sh

clear
printf "Hi, $USER! 👋\n"
printf "Let's get you set up... 👨‍💻\n"
# For dramatic effect...
sleep 2s


#######################################
# Symlinks
#######################################
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
ln -s  "$dotfiles_dir/karabiner/karabiner.edn" ~/.config/karabiner.edn
ln -s "$dotfiles_dir/karabiner/goku.log" ~/Library/Logs/goku.log

#######################################
# MacOS installs
#######################################
# TODO: Store some kind of variable in a gitignored file. Use it to only run this command once for a whole machine (i.e. on a fresh macOS install)
log "Updating MacOS apps"
# Install latest macOS and Apple Apps (Safari, etc.)
# softwareupdate -i -a

# Check for Homebrew, install if we don't have it
if test ! $(which brew); then
    log "Homebrew: Installing homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
fi

log "Homebrew: Updating recipes..."
brew update

log "Homebrew: Installing and upgrading packages..."
brew bundle

log "Homebrew: Starting services..."
# Based on documentation I've read, Homebrew _should_ automatically start these services up on boot indefinitely
brew services start goku
# Auto update and upgrade brew packages
brew autoupdate --start --upgrade --enable-notification --cleanup

#######################################
# MacOS
#######################################
source macos.sh

#######################################
# Fin
#######################################

log "All done. Have fun! 🚀"