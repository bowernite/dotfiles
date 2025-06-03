#!/usr/bin/env bash
#
# Script to set up a new machine (currently only for macOS)
#
# This should be idempotent so it can be run multiple times.
#
# Reading:
#
# - http://lapwinglabs.com/blog/hacker-guide-to-setting-up-your-mac
# - https://gist.github.com/MatthewMueller/e22d9840f9ea2fee4716
# - https://news.ycombinator.com/item?id=8402079
# - http://notes.jerzygangi.com/the-best-pgp-tutorial-for-mac-os-x-ever/

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
touch_dir ~/src/playground

touch ~/src/personal/dotfiles/.zshrc__private
touch ~/src/work/.gitconfig

##############################################################
# Begin
##############################################################

source ~/src/personal/dotfiles/bin/utils.sh
cd $dotfiles_dir

clear
printf "Hi, $USER! 👋\n"
printf "Let's get you set up... 💻\n"
# For dramatic effect...
sleep 2s

##############################################################
# Symlinks
##############################################################
log "Symlinking appropriate files to the \$HOME directory ($HOME)"

install_dotfile "zsh/zshrc" ".zshrc"
install_dotfile "zsh/zshrc__generated" ".zshrc__generated"
install_dotfile "zsh/zshrc__aliases" ".zshrc__aliases"
install_dotfile "zsh/zshrc__private" ".zshrc__private"
install_dotfile "git/gitconfig" ".gitconfig"
install_dotfile "git/gitignore_global" ".gitignore_global"
install_dotfile "vim/vimrc" ".vimrc"
install_dotfile "vim/vimrc__defaults" ".vimrc__defaults"
install_dotfile "shell/sandboxrc" ".sandboxrc"
install_dotfile "shell/yabairc" ".yabairc"

##############################################################
# Karabiner symlinking
##############################################################
log "Symlinking files/dirs for Karabiner Elements and Goku"

kb_root_dir="$HOME/.config/karabiner"
kb_dotfiles_dir="$dotfiles_dir/karabiner"

[[ -d "$HOME/.config" ]] || mkdir "$HOME/.config"

# Remove existing Karabiner directory/symlink if it exists
if [[ -L "$kb_root_dir" ]]; then
  echo "Removing existing Karabiner symlink: $kb_root_dir"
  rm "$kb_root_dir"
elif [[ -d "$kb_root_dir" ]]; then
  echo "Removing existing Karabiner directory: $kb_root_dir"
  rm -rf "$kb_root_dir"
fi

echo "Creating Karabiner symlink: $kb_root_dir -> $kb_dotfiles_dir"
ln -sf "$kb_dotfiles_dir" "$kb_root_dir"
if [[ $? != 0 ]]; then
  echo "🚨 unable to link Karabiner Root directory to the dotfiles directory (${kb_root_dir} to ${kb_dotfiles_dir})"
  return 1
fi

# Goku symlinks - remove existing before creating new ones
if [[ -L ~/.config/karabiner.edn ]]; then
  echo "Removing existing karabiner.edn symlink"
  rm ~/.config/karabiner.edn
elif [[ -e ~/.config/karabiner.edn ]]; then
  echo "Removing existing karabiner.edn file"
  rm ~/.config/karabiner.edn
fi

echo "Creating karabiner.edn symlink"
ln -s "$dotfiles_dir/karabiner/karabiner.edn" ~/.config/karabiner.edn

touch "$dotfiles_dir/karabiner/goku.log"

if [[ -L ~/Library/Logs/goku.log ]]; then
  echo "Removing existing goku.log symlink"
  rm ~/Library/Logs/goku.log
elif [[ -e ~/Library/Logs/goku.log ]]; then
  echo "Removing existing goku.log file"
  rm ~/Library/Logs/goku.log
fi

echo "Creating goku.log symlink"
ln -s "$dotfiles_dir/karabiner/goku.log" ~/Library/Logs/goku.log

##############################################################
# Software installs (homebrew, npm/yarn, etc.)
##############################################################

source setup/brew.sh

# Might change this at some point if we go full yarn. Still, it _is_ nice to have npx for "use the local binary if it's there, otherwise use the global one". AFAIK, that doesn't exist with yarn. It's useful for our shell aliases for running prettier, jest, etc.
if ! command -v npx &>/dev/null; then
  echo "Installing npx globally"
  yarn global add npx
fi

echo "Installing global npm packages"
npm i -g concurrently

# Install oh-my-zsh
# Check if $ZSH variable doesn't exist (hence, oh-my-zsh is already installed)
if [[ -z $ZSH ]]; then
  echo "Installing oh-my-zsh"
  # Look here for updated instructions if this is broken: https://github.com/ohmyzsh/ohmyzsh
  sudo sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# FZF setup for keybindings and fuzzy completion
# The setup generates this file, so check for its existence before doing it unnecessarily
if [[ ! -e ~/.fzf.zsh ]]; then
  echo "Installing fzf keybindings and fuzzy completion..."
  $(brew --prefix)/opt/fzf/install
fi

echo "Installing go packages"
go get -u github.com/nikitavoloboev/gitupdate
# Used by VS Code Go extensions
go get -v github.com/ramya-rao-a/go-outline
go get -v golang.org/x/tools/gopls
go get -v github.com/uudashr/gopkgs/v2/cmd/gopkgs
go get -v github.com/go-delve/delve/cmd/dlv
go get -v golang.org/x/lint/golint

# Vim plugins with vim-plug
if [[ ! -e ~/.vim/autoload/plug.vim ]]; then
  echo "Installing vim-plug"
  curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  echo "Installing all Vim plugins with PlugInstall"
  vim +PlugInstall +qall
fi

##############################################################
# macOS
##############################################################

source setup/macos.sh

##############################################################
# Repo setup
##############################################################

function clone_repo() {
  local repo_name=$1
  local target_dir="$HOME/src/personal/$repo_name"
  if [[ ! -d $target_dir ]]; then
    git clone "https://github.com/bowernite/$repo_name.git" $target_dir
  fi
}

clone_repo base-project-config
clone_repo abramczyk.dev
clone_repo doofi

# Install node_modules in any node projects (just when the machine is first set up)
cd ~/src/personal/abramczyk.dev
if [[ ! -d node_modules ]]; then
  echo "Installing node_modules in: $pwd"
  yarn
fi

##############################################################
# Fin
##############################################################

log "All done. Have fun! 🚀"
