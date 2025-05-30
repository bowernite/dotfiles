#!/usr/bin/env bash

SOURCE="https://github.com/bowernite/dotfiles"
TARBALL="$SOURCE/tarball/master"
TARGET="$HOME/src/personal/dotfiles"
TAR_CMD="tar -xzv -C "$TARGET" --strip-components=1 --exclude='{gitignore}'"

is_executable() {
  type "$1" >/dev/null 2>&1
}

if is_executable "git"; then
  CMD="git clone $SOURCE $TARGET"
elif is_executable "curl"; then
  CMD="curl -#L $TARBALL | $TAR_CMD"
elif is_executable "wget"; then
  CMD="wget --no-check-certificate -O - $TARBALL | $TAR_CMD"
fi

if [ -z "$CMD" ]; then
  echo "No git, curl or wget available. Aborting."
  exit 1
else
  echo "Installing dotfiles..."
  mkdir -p "$TARGET"
  eval "$CMD"
fi
