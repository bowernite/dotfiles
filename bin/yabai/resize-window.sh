#!/bin/bash

MAX_WIDTH=800

# Get info about the focused window and its application
window_info=$(yabai -m query --windows --window)
app_name=$(echo $window_info | jq -r '.app')
width=$(echo $window_info | jq -r '.frame.w')

# Check if the focused window is from the target app
if [ "$app_name" = "YourAppName" ]; then
  if [ $width -gt $MAX_WIDTH ]; then
    yabai -m window --resize abs:$MAX_WIDTH:0
  fi
fi
