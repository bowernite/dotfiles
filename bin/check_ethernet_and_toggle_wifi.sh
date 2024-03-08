#!/bin/bash

# Get the Ethernet connection status
ethernet_status=$(ifconfig en6 | grep status: | awk '{print $2}')

# Check if the Ethernet is active
if [ "$ethernet_status" = "active" ]; then
  # Turn off WiFi
  networksetup -setairportpower en0 off
else
  # Turn on WiFi (optional, remove if you only want to turn off WiFi)
  networksetup -setairportpower en0 on
fi
