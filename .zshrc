#########
# Imports
#########

# Yeah... I mean ideally this would be computed and not so nashty, but deriving this doesn't seem too easy because of symlinking -- unless the zsh session is launched from this directory, it always thinks the current directory is $HOME, the directory of the symlink target `.zshrc`
dotfiles_dir="$HOME/dotfiles"

# `|| true` swallows the error, but it'll still log it
# Generated when initializing zsh
source $dotfiles_dir/.zshrc__generated || true
# Private stuff (keys, company-specific, etc.)
if [ -e $dotfiles_dir/.zshrc__private ]; then
  source $dotfiles_dir/.zshrc__private
fi
source $dotfiles_dir/.zshrc__aliases || true

#########
# Other
#########

export NVM_DIR="$HOME/.nvm"
    [ -s "$(brew --prefix)/opt/nvm/nvm.sh" ] && . "$(brew --prefix)/opt/nvm/nvm.sh" # This loads nvm
    [ -s "$(brew --prefix)/opt/nvm/etc/bash_completion.d/nvm" ] && . "$(brew --prefix)/opt/nvm/etc/bash_completion.d/nvm" # This loads nvm bash_completion

# Setting PATH for Python 3.8
# The original version is saved in .bash_profile.pysave
PATH="/Library/Frameworks/Python.framework/Versions/3.8/bin:${PATH}"
export PATH

# Setting PATH for mongodb
PATH="/Users/abr1402/mongodb/bin:${PATH}"
export PATH

# Prompt customization
# Puts a new line after all prompts
precmd() {
    precmd() {
        echo
    }
}
# Two-line prompt
PROMPT="$PROMPT"$'\n'"😀 "

# fzf autocompletion
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

export FZF_DEFAULT_COMMAND='git ls-tree -r --name-only HEAD 2>/dev/null || fd --type f --hidden --follow --exclude="**/{node_modules,.git,.Trash}/*"'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --exclude="**/{node_modules,.git,.Trash}"'

# Use fd to generate the list for directory completion
_fzf_compgen_dir() {
  fd --type d --hidden --exclude="**/{node_modules,.git,.Trash}" . "$1"
}
_fzf_compgen_path() {
  git ls-tree -r --name-only HEAD 2>/dev/null || fd --type f --hidden --follow --exclude="**/{node_modules,.git,.Trash}/*" . "$1"
}
