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

install_dotfile ".zshrc"
install_dotfile ".zshrc__generated"
install_dotfile ".zshrc__aliases"
install_dotfile ".zshrc__private"
install_dotfile ".gitconfig"
install_dotfile ".gitignore_global"
install_dotfile ".vimrc"
install_dotfile ".vimrc__defaults"
install_dotfile ".sandboxrc"

##############################################################
# Karabiner symlinking
##############################################################
log "Symlinking files/dirs for Karabiner Elements and Goku"

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
# Software installs (homebrew, npm/yarn, etc.)
##############################################################

source setup/brew.sh

# Might change this at some point if we go full yarn. Still, it _is_ nice to have npx for "use the local binary if it's there, otherwise use the global one". AFAIK, that doesn't exist with yarn. It's useful for our shell aliases for running prettier, jest, etc.
if ! command -v npx &> /dev/null; then
  npm i -g npx
fi

echo "Installing oh-my-zsh"
# Look here for updated instructions if this is broken: https://github.com/ohmyzsh/ohmyzsh
sudo sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

echo "Installing fzf keybindings and fuzzy completion..."
$(brew --prefix)/opt/fzf/install

echo "Installing go packages"
go get -u github.com/nikitavoloboev/gitupdate

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
# TODO: Store some kind of variable in a gitignored file. Use it to only run this command once for a whole machine (i.e. on a fresh macOS install)
log "Updating MacOS apps"
# Install latest macOS and Apple Apps (Safari, etc.)
# softwareupdate -i -a

source setup/macos.sh

##############################################################
# Clone git repos
##############################################################

function clone_repo() {
  local repo_name=$1
  local target_dir="$HOME/src/personal/$repo_name"
  if [[ ! -d $target_dir ]]; then
    git clone "https://github.com/babramczyk/$repo_name.git" $target_dir
  fi
}

clone_repo base-project-config
clone_repo abramczyk.dev
clone_repo doofi

# TODO: Clean this up
cd ~/src/personal/abramczyk.dev
yarn

##############################################################
# Fin
##############################################################

log "All done. Have fun! 🚀"