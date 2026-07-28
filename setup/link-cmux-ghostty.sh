#!/usr/bin/env bash
#
# Symlinks cmux + Ghostty config from this repo into ~/.config so settings
# follow the machine. Idempotent: safe to re-run.
#
# The repo file is the source of truth. ~/.config/cmux/cmux.json and
# ~/.config/ghostty are symlinks pointing back here, so edits and writes land
# in the repo and show up as git changes.

set -euo pipefail

dotfiles_dir="${dotfiles_dir:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$dotfiles_dir/bin/global-utils/safe-symlink.sh"

ts="$(date +%Y%m%d-%H%M%S)"
cmux_bin="/Applications/cmux.app/Contents/Resources/bin/cmux"
manual_steps=()

# Moves a real (non-symlink) config out of the way before we replace it with a
# symlink, so a machine's existing settings are never silently destroyed.
backup_if_real() {
  local path="$1"
  if [[ -e "$path" && ! -L "$path" ]]; then
    local backup="$path.$ts.bak"
    echo "  Existing config found; backing up -> $backup"
    mv "$path" "$backup"
  fi
}

echo "Linking cmux + Ghostty config from $dotfiles_dir"

mkdir -p "$HOME/.config/cmux"

# cmux: only cmux.json is the live config. settings.json is a legacy fallback
# and intentionally not tracked.
backup_if_real "$HOME/.config/cmux/cmux.json"
safe_symlink "$dotfiles_dir/cmux/cmux.json" "$HOME/.config/cmux/cmux.json"
echo "  ~/.config/cmux/cmux.json -> $dotfiles_dir/cmux/cmux.json"

# Ghostty: whole dir so custom themes/ travel too. cmux reads it for terminal
# appearance and keybinds.
backup_if_real "$HOME/.config/ghostty"
safe_symlink "$dotfiles_dir/ghostty" "$HOME/.config/ghostty"
echo "  ~/.config/ghostty -> $dotfiles_dir/ghostty"

# Apply immediately when cmux is installed and running; otherwise tell the user.
if [[ -x "$cmux_bin" ]]; then
  if "$cmux_bin" reload-config >/dev/null 2>&1; then
    echo "  Reloaded cmux config (no restart needed)"
  else
    manual_steps+=("Start cmux, then run: cmux reload-config")
  fi
else
  manual_steps+=("Install cmux (https://cmux.com), then re-run: make link-cmux")
fi

if ! command -v ghostty >/dev/null 2>&1 && [[ ! -d /Applications/Ghostty.app ]]; then
  manual_steps+=("Ghostty isn't installed. Only needed if you use it standalone; cmux reads this config either way.")
fi

# Surface any backups we made so the user can reconcile old settings.
shopt -s nullglob
backups=("$HOME/.config/cmux/cmux.json.$ts.bak" "$HOME/.config/ghostty.$ts.bak")
for b in "${backups[@]}"; do
  [[ -e "$b" ]] && manual_steps+=("Your previous settings were saved to $b — merge anything you want to keep into the repo file, then delete it.")
done
shopt -u nullglob

echo
echo "Done. Source of truth is $dotfiles_dir/cmux/cmux.json"
echo "Edit it, then run 'cmux reload-config' to apply. Commit to sync to other machines."

if (( ${#manual_steps[@]} )); then
  echo
  echo "Manual steps needed:"
  for step in "${manual_steps[@]}"; do
    echo "  - $step"
  done
fi

# Socket control is "automation": no password (so nothing secret lands in this
# public repo) while still admitting local automation clients like the launchd
# autocompact daemon. Flag the footgun rather than let someone leak a secret.
echo
echo "Note: socketControlMode is 'automation' (no password, nothing secret in git)."
echo "If you switch to 'password' mode, the password lives in cmux.json — keep it"
echo "out of commits, since this repo is public."
