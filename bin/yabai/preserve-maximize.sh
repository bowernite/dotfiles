################################################################################
# WIP for theoretically leveraging Yabai to keep windows maximized when moving them to a larger display. But once I started working on this, I realized this wasn't a problem anymore..? We'll see...
################################################################################

#!/bin/bash

# Get the ID of the window that triggered the event
window_id=$1

# Get the display of that window
new_display=$(yabai -m query --windows --window ${window_id} | jq -r '.display')

echo new_display

# Check if the window was maximized
frame=$(yabai -m query --windows --window ${window_id} | jq -r '.frame')
if [[ $frame == *"w:1440"* && $frame == *"h:900"* ]]; then
  # Maximize the window on the new display
  yabai -m window --id ${window_id} --grid 1:1:0:0:1:1
fi
