#!/bin/bash

# Refresh Time Machine exclusions for dependency/build directories.
#
# Time Machine path exclusions are static, so directories created after setup
# (new clones, new worktrees) get backed up unless re-scanned. This is idempotent
# and safe to run on a schedule.

set -uo pipefail

SRC_ROOT="${HOME}/src"

STATIC_PATHS=(
  "${HOME}/.bun/install/cache"
  "${HOME}/.cache"
  "${HOME}/.colima"
  "${HOME}/.gradle"
  "${HOME}/.npm"
  "${HOME}/.yarn"
  "${HOME}/go/pkg/mod"
  "${HOME}/Library/Application Support/Code/Cache"
  "${HOME}/Library/Application Support/Code/CachedData"
  "${HOME}/Library/Application Support/Cursor/CachedData"
  "${HOME}/Library/Application Support/Cursor/CachedExtensionVSIXs"
  "${HOME}/Library/Application Support/Cursor/Partitions"
  "${HOME}/Library/Application Support/Cursor/logs"
  "${HOME}/Library/Developer/CoreSimulator"
  "${HOME}/Library/Developer/Xcode/DerivedData"
  "${HOME}/Library/pnpm/store"
)

added=0
present=0

exclude() {
  local path="$1"
  [ -e "$path" ] || return 0
  if tmutil isexcluded "$path" 2>/dev/null | grep -q '\[Excluded\]'; then
    present=$((present + 1))
    return 0
  fi
  if sudo -A tmutil addexclusion -p "$path" 2>/dev/null; then
    added=$((added + 1))
    echo "  + $path"
  else
    echo "  ! failed: $path" >&2
  fi
}

for path in "${STATIC_PATHS[@]}"; do
  exclude "$path"
done

if [ -d "$SRC_ROOT" ]; then
  while IFS= read -r path; do
    exclude "$path"
  done < <(find "$SRC_ROOT" -type d \
    \( -name node_modules -o -name .next -o -name dist -o -name build \
       -o -name target -o -name venv -o -name .venv -o -name DerivedData \) \
    -prune -print 2>/dev/null)
fi

echo "Time Machine exclusions: ${added} added, ${present} already present"
