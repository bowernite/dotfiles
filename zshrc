dotfiles_dir=$HOME/src/personal/dotfiles

#####################################################################

# The generated file that comes from oh-my-zsh
source $dotfiles_dir/zshrc__generated
# Private stuff (keys, company-specific, etc.)
source $dotfiles_dir/zshrc__private
source $dotfiles_dir/zshrc__aliases
source $dotfiles_dir/zshrc__git

#####################################################################
# PATH shenanigans
#####################################################################

# New M1 homebrew
PATH="/opt/homebrew/bin:$PATH"
eval "$(/opt/homebrew/bin/brew shellenv)"

# Set up for python, so that `python` can be invoked (i.e. instead of having to use `python3`). e.g. required for an Alfred workflow I use
## See: https://docs.brew.sh/Homebrew-and-Python
PATH="/opt/homebrew/opt/python/libexec/bin:$PATH"

# Setting PATH for mongodb
PATH="$HOME/mongodb/bin:$PATH"

# Setting PATH for Go executables
PATH="$HOME/go/bin:$PATH"

# Setting PATH for ruby and its gem executables
PATH="/usr/local/opt/ruby/bin:$PATH"
PATH="/usr/local/lib/ruby/gems/3.0.0/bin:$PATH"

# Homebrew recommended this be included in path
PATH="/usr/local/sbin:$PATH"

# For making GNU commands the default over the macOS/BSD ones
# I'm not actually sure one is better than the other. Though in `sed`'s case specifically, I wasted some time because the BSD version didn't have the options I needed/didn't match an answer I found online. So I don't know, maybe I'll change this back one day, or pick and choose when I actually want to make the GNU version the default. But for now, it's all I've specified in the `Brewfile`
## This one's huge, and just has a ton of basic commands
PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"
PATH="/opt/homebrew/opt/gnu-indent/libexec/gnubin:$PATH"
PATH="/opt/homebrew/opt/gnu-sed/libexec/gnubin:$PATH"
PATH="/opt/homebrew/opt/gnu-tar/libexec/gnubin:$PATH"
PATH="/opt/homebrew/opt/gnu-which/libexec/gnubin:$PATH"
PATH="/opt/homebrew/opt/gawk/libexec/gnubin:$PATH"
PATH="/opt/homebrew/opt/gnutls/bin:$PATH"
PATH="/opt/homebrew/opt/grep/libexec/gnubin:$PATH"
PATH="/opt/homebrew/opt/make/libexec/gnubin:$PATH"

export PATH

#####################################################################
# Shell prompt
#####################################################################

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

#####################################################################
# Git
#####################################################################

# Enable git auto-completion
## Source: https://www.oliverspryn.com/blog/adding-git-completion-to-zsh
zstyle ':completion:*:*:git:*' script ~/.zsh/git-completion.bash
fpath=(~/.zsh $fpath)
autoload -Uz compinit && compinit

#####################################################################
# FZF
#####################################################################

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

#####################################################################
# Navigation
#####################################################################

# When typing a command that can't be executed, and the command is the name of the directory, cd into it. Also works with autocomplete
# Source: http://zsh.sourceforge.net/Doc/Release/Options.html
setopt auto_cd

cdpath=($HOME/src $HOME/src/work $HOME/src/personal $HOME/playground $HOME/Dropbox)

# Show named and cdpath directories in autocomplete suggestions
# Source: https://superuser.com/questions/515633/my-zsh-autocompletion-for-cdpath-stopped-working
zstyle ':completion:*:complete:(cd|pushd):*' tag-order \
  'local-directories named-directories path-directories'

#####################################################################
# zsh plugins
#####################################################################

# Install Zinit (added by Zinit's installer)
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load specific plugins
## Off for now, until we need it
# zinit load wfxr/forgit

#####################################################################
# Graphite
#####################################################################

# (autogenerated by Graphite)
#compdef gt
###-begin-gt-completions-###
#
# yargs command completion script
#
# Installation: /opt/homebrew/bin/gt completion >> ~/.zshrc
#    or /opt/homebrew/bin/gt completion >> ~/.zprofile on OSX.
#
_gt_yargs_completions()
{
  local reply
  local si=$IFS
  IFS=$'
' reply=($(COMP_CWORD="$((CURRENT-1))" COMP_LINE="$BUFFER" COMP_POINT="$CURSOR" /opt/homebrew/bin/gt --get-yargs-completions "${words[@]}"))
  IFS=$si
  _describe 'values' reply
}
compdef _gt_yargs_completions gt
###-end-gt-completions-###

#####################################################################
# Miscellaneous setup
#####################################################################

# Load sandboxd to lazy load some things
# Source: https://github.com/benvan/sandboxd
# See sandboxrc for details
# Turning this off for now -- current position has a node requirement in package.json that prevents a lot of things from running if the correct node version isn't available. So for now, going to roll without sandboxd
# source $dotfiles_dir/bin/sandboxd

export NVM_DIR="$HOME/.nvm"
# Normally, nvm wants us to run these lines to load nvm on shell startup. But instead, we're using sandboxd to lazy load nvm logic to keep shell startup snappy af
[ -s "$(brew --prefix)/opt/nvm/nvm.sh" ] && . "$(brew --prefix)/opt/nvm/nvm.sh"                                       # This loads nvm
[ -s "$(brew --prefix)/opt/nvm/etc/bash_completion.d/nvm" ] && . "$(brew --prefix)/opt/nvm/etc/bash_completion.d/nvm" # This loads nvm bash_completion

# Skip all annoying commit hooks
# WIP, not really tested yet
export HUSKY_SKIP_HOOKS=1
if [[ -z $has_aliased_npx ]]; then
  npx() {
    # shfmt doesn't like this ¯\_(ツ)_/¯
    # local -i i=$argv[(i)^-*]
    # $argv[i] is the first non-option argument (or empty if there is none).
    local is_bad=0
    case $argv[i] in
    commitlint | lint-staged) is_bad=1 ;;
    esac
    if [[ $is_bad == 0 ]]; then
      command npx "$@"
    fi
  }
  export has_aliased_npx=1
fi

# Symlink local executables into a path-accessible place
## NOTE: See that file in this repo for notes on why we're not symlinking this for the time being
# if [[ ! -L "/usr/local/bin/gcim" ]]; then
#   ln -s "$dotfiles_dir/bin/gcim" "/usr/local/bin/gcim"
# fi

# Don't know why this isn't available to set in gitconfig globally, but 🤷‍♂️
export GIT_MERGE_AUTOEDIT=no

# Enable zsh-syntax-highlighting.
# NOTE: Per this package's documentation, this needs to be at the end of this file
