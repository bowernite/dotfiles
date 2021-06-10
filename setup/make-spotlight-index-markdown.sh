#!/usr/bin/env bash

# Exit the script if there's an error
set -e

# --------------------------------------------------------------
# Markdown spotlight importer.
# --------------------------------------------------------------

# Problem: by default, OS X doesn't index the content of markdown files.
# Which is kind of unfortunate, because that's really useful with Alfred.
# So, let's add an importer.

# A Markdown file is just a text file, after all. We just re-use the RichText
# importer and customize it for Markdown (ie., recognize Markdown format).
# Bonus: this method does not require to bypass SIP.

# Source: https://github.com/solarsailer/dotfiles/blob/a4771c67a163533ecc5bda47d19302dafb82ca83/scripts/markdown-spotlight-importer.bash

dotfiles_dir=$HOME/src/personal/dotfiles

if [[ ! -e /Library/Spotlight/Markdown.mdimporter ]]; then
  # Just to make this idempotent, scrap any work we've already done through this script so we can start fresh and try it again
  sudo rm -rf /Library/Spotlight/Markdown.mdimporter

  # Create a copy of the system `RichText.mdimporter`.
  cp -r /System/Library/Spotlight/RichText.mdimporter $dotfiles_dir

  # Change it to only index markdown files.
  patch -p2 $dotfiles_dir/RichText.mdimporter/Contents/Info.plist <$dotfiles_dir/setup/Markdown.mdimporter.patch
  # NOTE: The .patch file can be super tricky. It expects certain characters for end of lines (e.g. LF vs CRLF) that I'm not exactly sure of. If it breaks again and you get an error like "unexpected end of line" in diff, try reverting back to an old version of the patch file and making your new changes carefully

  # Move it into `/Library/Spotlight` as `Markdown.mdimporter`.
  sudo mv $dotfiles_dir/RichText.mdimporter /Library/Spotlight/Markdown.mdimporter

  # Re-index with the new importer.
  mdimport -r /Library/Spotlight/Markdown.mdimporter
fi
