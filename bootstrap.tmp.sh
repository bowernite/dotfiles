#######################################
# Maybe one day...
#
# These might be helpful at some point,
# but they aren't right now
######################################

# Install GNU core utilities (those that come with OS X are outdated)
# TODO: Maybe check these out? See if they're better, and use these if they are
# echo "Homebrew: Installing better GNU utilities..."
# brew tap homebrew/dupes
# brew install coreutils
# brew install gnu-sed --with-default-names
# brew install gnu-tar --with-default-names
# brew install gnu-indent --with-default-names
# brew install gnu-which --with-default-names
# brew install gnu-grep --with-default-names
# Install GNU `find`, `locate`, `updatedb`, and `xargs`, g-prefixed
# TODO: Maybe check this out
# brew install findutils

# echo "Homebrew: Installing fonts..."
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

# Require password as soon as screensaver or sleep mode starts
# defaults write com.apple.screensaver askForPassword -int 1
# defaults write com.apple.screensaver askForPasswordDelay -int 0

# Q: Is this going to duplicate stuff that we already have committed to .zshrc?
# TODO: prevent the install from prompting when this is installed
# echo "Installing fzf keybindings and fuzzy completion..."
# $(brew --prefix)/opt/fzf/install
