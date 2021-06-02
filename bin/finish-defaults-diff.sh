#!/bin/bash

#################################################
# Finish the process of diffing `defaults` by comparing the "before" and "after" snapshots
#################################################

defaults read >bin/.out/defaults-after.plist

# Diff with VS Code
code --diff bin/.out/defaults-before.plist bin/.out/defaults-after.plist
