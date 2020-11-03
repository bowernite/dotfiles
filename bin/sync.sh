#!/bin/zsh

echo "🔀 Syncing home directories with the ones in this repo"

echo "⏳ Syncing ~/.config/karabiner/assets/complex_modifications…"
cp -R ~/.config/karabiner/assets/complex_modifications .config/karabiner/assets

echo "✅ All done!"