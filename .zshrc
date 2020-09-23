#########
# Imports
#########

# `|| true` swallows the error, but it'll still log it

# Generated when initializing zsh
source ~/.zshrc__generated || true
# Private stuff (keys, company-specific, etc.)
source ~/.zshrc__private || true
source ~/.zshrc__aliases || true

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

export FZF_DEFAULT_COMMAND='git ls-tree -r --name-only HEAD || fd --type f --hidden --follow --exclude "**/{node_modules,.git,.Trash}/*"'
