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

echo "Hi, $USER! 👋"
echo "Let's get you set up... 👨‍💻"
echo ""

echo "Pulling in some shell helpers"
source bootstrap-helpers.sh

#######################################
# Symlinks
#######################################
echo "Symlinking dotfiles to \$HOME: $HOME"

install_dotfile ".zshrc"
install_dotfile ".gitconfig"
install_dotfile ".vimrc"

#######################################
# Homebrew
#######################################
echo "Homebrew: Starting Homebrew installations"

# Check for Homebrew, install if we don't have it
if test ! $(which brew); then
    echo "Installing homebrew..."
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

echo "Homebrew: Updating recipes..."
brew update

echo "Homebrew: Upgrading existing packages"
brew upgrade

echo "Homebrew: Installing generic packages..."
HOMEBREW_PACKAGES=(
    bitwarden-cli
    fzf
    git
    nvm
    python
    yarn
    # Q: Are these necessary, or do they come with nvm?
    # node
    # npm
)
brew install ${HOMEBREW_PACKAGES[@]}

echo "Homebrew: Cleaning up..."
brew cleanup

echo "Homebrew: Installing Homebrew cask..."
brew install caskroom/cask/brew-cask

echo "Homebrew: Installing cask apps..."
HOMEBREW_CASKS=(
    alfred
    bartender
    docker
    firefox
    flux
    google-chrome
    gpg-suite
    karabiner-elements
    postman
    slack
    spectacle
    spotify
    virtualbox
    zoomus
)
brew cask install ${HOMEBREW_CASKS[@]}

# Q: Is this going to duplicate stuff that we already have committed to .zshrc?
# TODO: prevent the install from prompting when this is installed
echo "Installing fzf keybindings and fuzzy completion..."
$(brew --prefix)/opt/fzf/install

#######################################
# MacOS
#######################################
echo " Configuring MacOS..."
# TODO: See which other preferences I normally use, how to set them from the shell, then add them to this list

# Set fast key repeat rate
defaults write NSGlobalDomain KeyRepeat -int 2

# Show filename extensions by default
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

#######################################
# Fin
#######################################

echo ""
echo "All done. Have fun! 🚀"