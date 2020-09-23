#########
# Imports
#########

# `|| true` swallows the error, but it'll still log it

# Generated when initializing zsh
source ~/.zshrc__generated || true
# Private stuff (keys, company-specific, etc.)
source ~/.zshrc__private || true

#########
# Aliases
#########
alias format='echo "💅 Formatting files with Prettier..." && npx prettier --write --loglevel=error . && echo "✅ Done formatting"'
alias lint='echo "🔎 Linting files with ESLint..." && npx eslint . && echo "✅ Done linting"'
alias tc='echo "🧐 Type-checking files with TypeScript..." && npx tsc --noEmit && echo "✅ Done type-checking"'
alias test='echo "🧪 Testing files with Jest..." && npx jest --coverage=false && echo "✅ Done testing"'
alias testw='echo "🧪👀 Testing files with Jest on watch..." && npx jest --watch --coverage=false'
alias va='tc && test && lint && format'
alias vs='tc && lint && format'
# dotfiles repo
alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'
# Open fzf files with vim by default
alias go="vim -o \`fzf\`"


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
