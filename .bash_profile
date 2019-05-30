# Parse the current git branch's name
function parse_git_branch {
      ref=$(git symbolic-ref HEAD 2> /dev/null) || return
            echo "("${ref#refs/heads/}")"
}

# This section adds the directory path and Git branch name into the CLI, to the left.
PS1="\n\[\033[32m\]\W\[\033[33m\]\$(parse_git_branch)\[\033[00m\] $ "
export PS1
