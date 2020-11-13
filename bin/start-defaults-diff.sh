#!/bin/bash

#################################################
# Start the process of changing and diffing preferences through the `defaults command`
#################################################

# Clean earlier runs, for sanity
if [[ -e bin/.out/defaults-before.plist ]]; then
  rm bin/.out/defaults-before.plist
fi
if [[ -e bin/.out/defaults-after.plist ]]; then
  rm bin/.out/defaults-after.plist
fi

defaults read > bin/.out/defaults-before.plist