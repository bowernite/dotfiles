#!/bin/bash

################################################################################
# Tells ya how many macos text replacements I have 💪🏼💪🏼💪🏼💪🏼💪🏼
#
# Arguments:
#   (none)

line_count=$(wc -l <notes/macos-text-replacements.plist)

# Lines where I blabber on about how great macOS text replacements are. But also more importantly how great *I* am
comment_lines=3

# Lines to account for the parentheses that surround the entire object
paren_lines=2

# Number of lines each replacement takes up
lines_per_replacement=5

((num_replacements = (line_count - comment_lines - paren_lines) / 5))

bold=$(tput bold)
normal=$(tput sgr0)
echo "You have... 🥁"
echo "${bold}${num_replacements}${normal} text replacements 🎉"
