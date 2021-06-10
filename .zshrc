dotfiles_dir=$HOME/src/personal/dotfiles

##############################################################
# Imports
##############################################################

# The generated file that comes from oh-my-zsh
source $dotfiles_dir/.zshrc__generated
# Private stuff (keys, company-specific, etc.)
source $dotfiles_dir/.zshrc__private
source $dotfiles_dir/.zshrc__aliases

##############################################################
# PATH shenanigans
##############################################################

# Setting PATH for Python 3.8
# The original version is saved in .bash_profile.pysave
PATH="/Library/Frameworks/Python.framework/Versions/3.8/bin:${PATH}"

# Setting PATH for mongodb
PATH="$HOME/mongodb/bin:${PATH}"

# Setting PATH for Go executables
PATH="$HOME/go/bin:${PATH}"

# For making GNU utilities the default over the macOS/BSD ones
PATH="/usr/local/opt/gnu-sed/libexec/gnubin:$PATH"

export PATH

##############################################################
# Shell prompt
##############################################################

# Puts a new line after all prompts
precmd() {
  precmd() {
    echo
  }
}

# Two-line prompt with emoji
# This is off for now... it go annoying with the emojis that were sometimes wider than one character, depending on the terminal that was rendering it. Maybe one day I'll turn it back on and move the emoji or just use emojis that are always one character wide (e.g. 😀)
# Source: https://github.com/kentcdodds/dotfiles/blob/master/.zshrc
function random_element {
  declare -a array=("$@")
  r=$((RANDOM % ${#array[@]}))
  printf "%s\n" "${array[$r]}"
}
function random_emoji() {
  printf "$(random_element 😅 👽 🔥 👻 ⛄ 👾 🍔 😄 🍰 🐑 😎 🏎 🤖 😇 😼 💪 🦄 🥓 🌮 🎉 💯 ⚛️ 🐠 🐳 🐿 🥳 🤩 🤯 🤠 👨‍💻 🦸‍ 🧝‍ 🧞‍ 🧙‍ 👨‍🚀 👨‍🔬 🕺 🦁 🐶 🐵 🐻 🦊 🐙 🦎 🦖 🦕 🦍 🦈 🐊 🦂 🐍 🐢 🐘 🐉 🦚 ✨ ☄️ ⚡️ 💥 💫 🧬 🔮 ⚗️ 🎊 🔭 ⚪️ 🔱)"
}
# PROMPT="$PROMPT"$'\n'"$(random_emoji)  "

PROMPT="$PROMPT"$'\n'"  "

##############################################################
# FZF
##############################################################

# fzf autocompletion
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

FZF_EXCLUDE_GLOB="**/{node_modules,.git,.Trash,Library,Music,.node-gyp,.npm}"

export FZF_DEFAULT_COMMAND="fd --hidden --follow --exclude='$FZF_EXCLUDE_GLOB'"
# This version only looks for files through git. But this can be annoying sometimes (when git doesn't know about files yet, for example). So going to try only leveraging the exclude glob above, and seeing if that's better. Also, `fd` respects gitignore by default. So the only thing piping `git ls-tree` is really providing here is ignoring untracked files, which... no
# export FZF_DEFAULT_COMMAND="git ls-tree -r --name-only HEAD 2>/dev/null || fd --hidden --follow --exclude='$FZF_EXCLUDE_GLOB'"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type d --hidden --exclude='$FZF_EXCLUDE_GLOB'"

# Use fd to generate the list for directory completion
_fzf_compgen_dir() {
  fd --type d --hidden --exclude=$FZF_EXCLUDE_GLOB . $1
}
_fzf_compgen_path() {
  fd --type f --hidden --follow --exclude=$FZF_EXCLUDE_GLOB . $1
  # See notes above on rationale for not using git here
  # If it's a git repo, only search for files tracked by git
  # Otherwise, just use fd
  # git ls-tree -r --name-only HEAD 2>/dev/null $1 || fd --type f --hidden --follow --exclude=$FZF_EXCLUDE_GLOB . $1
}

##############################################################
# Navigation
##############################################################

# When typing a command that can't be executed, and the command is the name of the directory, cd into it. Also works with autocomplete
# Source: http://zsh.sourceforge.net/Doc/Release/Options.html
setopt auto_cd

cdpath=($HOME/src $HOME/src/work $HOME/src/personal $HOME/playground $HOME/Dropbox)

# Show named and cdpath directories in autocomplete suggestions
# Source: https://superuser.com/questions/515633/my-zsh-autocompletion-for-cdpath-stopped-working
zstyle ':completion:*:complete:(cd|pushd):*' tag-order \
  'local-directories named-directories path-directories'

##############################################################
# Miscellaneous setup
##############################################################

# Load sandboxd to lazy load some things
# Source: https://github.com/benvan/sandboxd
# See .sandboxrc for details
# Turning this off for now -- current position has a node requirement in package.json that prevents a lot of things from running if the correct node version isn't available. So for now, going to roll without sandboxd
# source $dotfiles_dir/bin/sandboxd

export NVM_DIR="$HOME/.nvm"
# Normally, nvm wants us to run these lines to load nvm on shell startup. But instead, we're using sandboxd to lazy load nvm logic to keep shell startup snappy af
# [ -s "$(brew --prefix)/opt/nvm/nvm.sh" ] && . "$(brew --prefix)/opt/nvm/nvm.sh" # This loads nvm
# [ -s "$(brew --prefix)/opt/nvm/etc/bash_completion.d/nvm" ] && . "$(brew --prefix)/opt/nvm/etc/bash_completion.d/nvm" # This loads nvm bash_completion

# Use `bat` for syntax highlighting in man pages
export MANPAGER="sh -c 'col -bx | bat -l man -p --theme=$bat_theme'"

# Enable zsh-syntax-highlighting.
# NOTE: Per this package's documentation, this needs to be at the end of this file
source "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# Skip all annoying commit hooks
# WIP, not really tested yet
export HUSKY_SKIP_HOOKS=1
if [[ -z $has_aliased_npx ]]; then
  npx() {
    echo 'in the function'
    # shfmt doesn't like this ¯\_(ツ)_/¯
    # local -i i=$argv[(i)^-*]
    # $argv[i] is the first non-option argument (or empty if there is none).
    local is_bad=0
    case $argv[i] in
    commitlint | lint-staged) is_bad=1 ;;
    esac
    echo 'is bad'
    echo $is_bad
    if [[ $is_bad == 0 ]]; then
      command npx "$@"
    fi
  }
  export has_aliased_npx=1
fi

# Symlink local executables into a path-accessible place
if [[ ! -L "/usr/local/bin/gcim" ]]; then
  ln -s "$dotfiles_dir/bin/gcim" "/usr/local/bin/gcim"
fi

# Don't know why this isn't available to set in gitconfig globally, but 🤷‍♂️
export GIT_MERGE_AUTOEDIT=no
