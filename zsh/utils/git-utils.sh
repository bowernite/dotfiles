#####################################################################
# Git utilities
#####################################################################

# get_changed_files returns a list of changed files between the current branch and a base branch,
# including staged changes and working directory changes.
# It takes two parameters:
# - pattern: A grep regex pattern to filter files by extension
# - base_branch: The base branch to compare against, defaults to origin/$(git_parent_branch) if not provided
function get_changed_files() {
  local pattern="$1"
  local base_branch="${2:-origin/$(git_parent_branch)}"
  
  # Get committed changes, staged changes, and working directory changes
  local changed_files
  changed_files=$({
    git diff --name-status $base_branch...HEAD 2>/dev/null
    git diff --name-status --cached 2>/dev/null
    git diff --name-status 2>/dev/null
  } | \
    awk '{if ($1 != "D" && ($1 == "M" || $1 == "A" || $1 == "R" || $1 == "T" || $1 == "C")) {print $NF}}' | \
    sort | uniq)
  
  # Only run git ls-files if we have files to check (handles macOS xargs without -r flag)
  if [[ -n "$changed_files" ]]; then
    echo "$changed_files" | xargs git ls-files -- 2>/dev/null | grep -E "$pattern"
  fi
}

# show_changed_files_preview prints a preview of changed files with their status.
# It takes two parameters:
# - pattern: A grep regex pattern to filter files by extension
# - base_branch: The base branch to compare against, defaults to origin/$(git_parent_branch) if not provided
function show_changed_files_preview() {
  local pattern="$1"
  local base_branch="${2:-origin/$(git_parent_branch)}"
  
  echo "🔍 Base branch: $base_branch"
  
  local preview=$(GIT_PAGER=cat git diff --color=always --name-status $base_branch...HEAD -- $(git diff --name-only $base_branch...HEAD | grep -E "$pattern") | grep -E '^[MA]\s')
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
# - base_branch: The base branch to compare against, defaults to origin/$(git_parent_branch) if not provided
function get_changed_frontend_files() {
  local base_branch="${1:-origin/$(git_parent_branch)}"
  get_changed_files '\.(js|jsx|ts|tsx|html|css|svelte|mjs)$' "$base_branch"
}

# get_changed_js_ts_files returns a list of changed JavaScript/TypeScript files.
# It takes one optional parameter:
# - base_branch: The base branch to compare against, defaults to origin/$(git_parent_branch) if not provided
function get_changed_js_ts_files() {
  local base_branch="${1:-origin/$(git_parent_branch)}"
  get_changed_files '\.(js|jsx|ts|tsx)$' "$base_branch"
}
