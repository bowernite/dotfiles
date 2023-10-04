#!/bin/bash

################################################################################
# Exit tiling without exiting bsp mode
################################################################################

# Get the ids of all the windows in the current space based on multiple conditions
window_ids=$(yabai -m query --windows --space | jq -r '.[] | select(."is-floating"==false and ."is-hidden"==false and ."is-visible"==true and ."is-native-fullscreen"==false and ."is-minimized"==false and ."has-fullscreen-zoom"==false) | .id')

echo $window_ids

# Toggle zoom-fullscreen for each of those windows
for id in $window_ids; do
  yabai -m window "$id" --toggle zoom-fullscreen
done
