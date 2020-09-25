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

echo "Starting bootstrapping"

# Check for Homebrew, install if we don't have it
if test ! $(which brew); then
    echo "Installing homebrew..."
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# Update homebrew recipes
echo "Updating homebrew recipes..."
brew update

# TODO: Maybe check these out? See if they're better, and use these if they are
# Install GNU core utilities (those that come with OS X are outdated)
# brew tap homebrew/dupes
# brew install coreutils
# brew install gnu-sed --with-default-names
# brew install gnu-tar --with-default-names
# brew install gnu-indent --with-default-names
# brew install gnu-which --with-default-names
# brew install gnu-grep --with-default-names

# Install GNU `find`, `locate`, `updatedb`, and `xargs`, g-prefixed
# TODO: Maybe check these out? See if they're better, and use these if they are
# brew install findutils

PACKAGES=(
    bitwarden-cli
    fzf
    git
    nvm
    # node
    # npm
    python
    python3
    yarn
)

echo "Installing packages..."
brew install ${PACKAGES[@]}

echo "Cleaning up..."
brew cleanup

echo "Installing fzf keybindings and fuzzy completion..."
$(brew --prefix)/opt/fzf/install

echo "Installing cask..."
brew install caskroom/cask/brew-cask

# REVIEW: "maybe" packages are commented out
CASKS=(
    adguard
    alfred
    # docker
    firefox
    flux
    google-chrome
    # google-drive
    # gpg-suite
    karabiner-elements
    # iterm2
    # macvim
    # postman
    slack
    spectacle
    # vanilla
    # virtualbox
    # vlc
    # zoomus
)

echo "Installing cask apps..."
brew cask install ${CASKS[@]}

# echo "Installing fonts..."
# brew tap caskroom/fonts
# FONTS=(
#     font-inconsolidata
#     font-roboto
#     font-clear-sans
# )
# brew cask install ${FONTS[@]}

# echo "Installing Python packages..."
# PYTHON_PACKAGES=(
#     ipython
#     virtualenv
#     virtualenvwrapper
# )
# sudo pip install ${PYTHON_PACKAGES[@]}

# echo "Installing global npm packages..."
# npm install marked -g

echo "Configuring OSX..."
# TODO: See which other preferences I normally use, how to set them from the shell, then add them to this list

# Set fast key repeat rate
defaults write NSGlobalDomain KeyRepeat -int 2

# Require password as soon as screensaver or sleep mode starts
# defaults write com.apple.screensaver askForPassword -int 1
# defaults write com.apple.screensaver askForPasswordDelay -int 0

# Show filename extensions by default
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Enable tap-to-click
# defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
# defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# echo "Creating folder structure..."
# [[ ! -d Wiki ]] && mkdir Wiki
# [[ ! -d Workspace ]] && mkdir Workspace

echo "Bootstrapping complete"
