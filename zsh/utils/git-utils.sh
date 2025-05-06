#####################################################################
# Git utilities
#####################################################################

# get_changed_files returns a list of changed files between the current branch and a base branch.
# It takes two parameters:
# - pattern: A grep regex pattern to filter files by extension
# - base_branch: The base branch to compare against (e.g., origin/main), defaults to origin/main if not provided
function get_changed_files() {
  local pattern="$1"
  local base_branch="${2:-origin/main}"
  
  git diff --name-status $base_branch...HEAD | \
    awk '{if ($1 != "D" && ($1 == "M" || $1 == "A")) {print $2}}' | \
    xargs git ls-files -- | \
    grep -F -x -f - <(git ls-tree -r --name-only HEAD) | \
    grep -E "$pattern"
}

# show_changed_files_preview prints a preview of changed files with their status.
# It takes two parameters:
# - pattern: A grep regex pattern to filter files by extension
# - base_branch: The base branch to compare against, defaults to origin/main if not provided
function show_changed_files_preview() {
  local pattern="$1"
  local base_branch="${2:-origin/$(git_dev_branch)}"
  
  GIT_PAGER=cat
  local preview=$(git diff --color=always --name-status $base_branch...HEAD -- $(git diff --name-only $base_branch...HEAD | grep -E "$pattern") | grep -E '^[MA]\s')
  echo "💅 Changed files to be validated:"
  echo -e "$preview"
  echo
}

# git_show_modified_files shows files that have been modified after validation and prompts for commit.
# It takes one parameter:
# - success: A boolean ("true" or "false") indicating whether validation was successful
function git_show_modified_files() {
  local success="$1"
  
  if [[ $(git status --porcelain) ]]; then
    echo
    echo -e "\033[0;33mThe following files have been modified:\033[0m"
    git status --porcelain
  fi
}

# get_changed_frontend_files returns a list of changed frontend files (js, jsx, ts, tsx, html, css).
# It takes one optional parameter:
# - base_branch: The base branch to compare against, defaults to origin/$(git_dev_branch) if not provided
function get_changed_frontend_files() {
  local base_branch="${1:-origin/$(git_dev_branch)}"
  get_changed_files '\.(js|jsx|ts|tsx|html|css)$' "$base_branch"
}

# get_changed_js_ts_files returns a list of changed JavaScript/TypeScript files.
# It takes one optional parameter:
# - base_branch: The base branch to compare against, defaults to origin/$(git_dev_branch) if not provided
function get_changed_js_ts_files() {
  local base_branch="${1:-origin/$(git_dev_branch)}"
  get_changed_files '\.(js|jsx|ts|tsx)$' "$base_branch"
}
