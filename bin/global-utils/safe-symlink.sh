#!/bin/sh

# Creates a symlink that's protected from being replaced by atomic/rename-based
# writes (e.g. editors with "safe write" mode). Writes *through* the symlink to
# the target still work normally.
#
# Uses macOS `chflags -h uchg` to make the symlink node itself immutable.
# -h is critical: without it, chflags follows the symlink and locks the target.
#
# Usage: safe_symlink <target> <link_path>
safe_symlink() {
  local target="$1"
  local link_path="$2"

  if [[ -z "$target" || -z "$link_path" ]]; then
    echo "Usage: safe_symlink <target> <link_path>"
    return 1
  fi

  # Clear immutable flag if re-creating an existing protected symlink
  # (no-op if link_path doesn't exist; errors suppressed intentionally)
  chflags -h nouchg "$link_path" 2>/dev/null || true

  if [[ -L "$link_path" ]]; then
    rm "$link_path"
  elif [[ -e "$link_path" ]]; then
    echo "Warning: $link_path exists and is not a symlink. Removing."
    rm -rf "$link_path"
  fi

  ln -s "$target" "$link_path"
  chflags -h uchg "$link_path"
}
