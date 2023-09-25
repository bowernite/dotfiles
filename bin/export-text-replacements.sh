#!/bin/bash

#################################################
# Export raw text replacements data using the `defaults` command, so that it can be backed up in case Apple ever decides to F me on these, which it probably will.
#
# For now, this just copies to clipboard so I can preserve other items in the export file (e.g. comments at the top)
#################################################

# Works as of macOS Ventura 13.5.2
defaults read -g NSUserDictionaryReplacementItems | pbcopy

echo "📋 Text replacements copied to clipboard"
