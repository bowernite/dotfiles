# This section adds the directory path and Git branch name into the CLI, to the left.
function parse_git_branch {
      ref=$(git symbolic-ref HEAD 2> /dev/null) || return
            echo "("${ref#refs/heads/}")"
}
PS1="\n\[\033[32m\]\W\[\033[33m\]\$(parse_git_branch)\[\033[00m\] $ "
export PS1
source ~/.bashrc
source ~/git-completion.bash

# for running locally
for f in ~/.local-config/*.sh; do source $f; done

export PATH=~/other-akitabox/akita/bin:$PATH

export PATH=~/.nvm:$PATH

export PATH=/Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin:$PATH

export NO_CODESYNC=true
