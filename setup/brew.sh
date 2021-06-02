#!/usr/bin/env bash

##############################################################
# Homebrew setup
##############################################################

source ~/src/personal/dotfiles/bin/utils.sh

# Check for Homebrew, install if we don't have it
if [[ $(command -v brew) == "" ]]; then
	log "Homebrew: Installing homebrew..."
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
fi

# I used to do this, but then got a weird message from Homebrew about GitHub and shallow cloning nonsense. I don't _think_ I need it anymore, provided I'm using Homebrew Autoupdate (see below)
# log "Homebrew: Updating recipes..."
# brew update

log "Homebrew: Installing and upgrading packages..."
# cd into the dotfiles directory, since that's where the `Brewfile` is
cd $dotfiles_dir
brew bundle

log "Homebrew: Starting services..."
# Based on documentation I've read, Homebrew _should_ automatically start these services up on boot indefinitely
if ! brew services list | grep goku >/dev/null; then
	brew services start goku
fi
# Auto update and upgrade brew packages
if ! brew autoupdate --status | grep "installed and running" >/dev/null; then
	brew autoupdate --start --upgrade --enable-notification --cleanup
fi
