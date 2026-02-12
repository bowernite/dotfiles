#!/bin/bash

# Wipe All Spotify Data from macOS
# This script removes Spotify application and all associated data, caches, and preferences

set -e

echo "=== Spotify Complete Removal ==="
echo ""
echo "This script will remove:"
echo "  - Spotify application (/Applications/Spotify.app)"
echo "  - All preferences (~/Library/Preferences/com.spotify.*)"
echo "  - Application support files (~/Library/Application Support/Spotify)"
echo "  - All caches (~/Library/Caches/com.spotify.*)"
echo "  - Saved application state (~/Library/Saved Application State/com.spotify.*)"
echo "  - Containers (~/Library/Containers/com.spotify.*)"
echo "  - Group containers (~/Library/Group Containers/com.spotify.*)"
echo "  - Logs (~/Library/Logs/Spotify)"
echo "  - Cookies (~/Library/Cookies/com.spotify.*)"
echo ""

# Check if Spotify is running
if pgrep -x "Spotify" > /dev/null; then
    echo "WARNING: Spotify is currently running."
    echo "Please quit Spotify before proceeding."
    echo ""
    echo "You can quit Spotify by:"
    echo "  1. Right-clicking the Spotify icon in the menu bar and selecting 'Quit Spotify'"
    echo "  2. Or using: killall Spotify"
    echo ""
    read -p "Do you want to force quit Spotify now? (yes/no): " force_quit
    
    if [ "$force_quit" = "yes" ]; then
        echo "Force quitting Spotify..."
        killall Spotify 2>/dev/null || true
        sleep 2
        
        # Check again
        if pgrep -x "Spotify" > /dev/null; then
            echo "Error: Could not quit Spotify. Please quit it manually and try again."
            exit 1
        fi
        echo "Spotify has been quit."
    else
        echo "Aborted. Please quit Spotify and run this script again."
        exit 0
    fi
    echo ""
fi

# Collect all Spotify-related locations
SPOTIFY_LOCATIONS=(
    "/Applications/Spotify.app"
    "$HOME/Library/Preferences/com.spotify.client.plist"
    "$HOME/Library/Preferences/com.spotify.client.helper.plist"
    "$HOME/Library/Application Support/Spotify"
    "$HOME/Library/Caches/com.spotify.client"
    "$HOME/Library/Caches/com.spotify.client.helper"
    "$HOME/Library/Saved Application State/com.spotify.client.savedState"
    "$HOME/Library/Containers/com.spotify.client"
    "$HOME/Library/Group Containers/com.spotify.client"
    "$HOME/Library/Logs/Spotify"
    "$HOME/Library/Cookies/com.spotify.client.binarycookies"
)

# Also check for any other Spotify-related files
echo "Scanning for Spotify-related files..."
echo ""

FOUND_LOCATIONS=()
for location in "${SPOTIFY_LOCATIONS[@]}"; do
    if [ -e "$location" ]; then
        FOUND_LOCATIONS+=("$location")
        if [ -d "$location" ]; then
            SIZE=$(du -sh "$location" 2>/dev/null | cut -f1)
            echo "  ✓ Found directory: $location ($SIZE)"
        else
            SIZE=$(ls -lh "$location" 2>/dev/null | awk '{print $5}')
            echo "  ✓ Found file: $location ($SIZE)"
        fi
    fi
done

# Search for any other Spotify-related files in common locations
echo ""
echo "Searching for additional Spotify files..."
ADDITIONAL_FILES=$(find "$HOME/Library/Preferences" "$HOME/Library/Caches" "$HOME/Library/Containers" "$HOME/Library/Group Containers" "$HOME/Library/Saved Application State" -name "*spotify*" -o -name "*Spotify*" 2>/dev/null | grep -v "^$" || true)

if [ -n "$ADDITIONAL_FILES" ]; then
    echo "Found additional Spotify-related files:"
    echo "$ADDITIONAL_FILES" | while read -r file; do
        if [ -e "$file" ]; then
            FOUND_LOCATIONS+=("$file")
            if [ -d "$file" ]; then
                SIZE=$(du -sh "$file" 2>/dev/null | cut -f1 || echo "unknown")
                echo "  ✓ $file ($SIZE)"
            else
                SIZE=$(ls -lh "$file" 2>/dev/null | awk '{print $5}' || echo "unknown")
                echo "  ✓ $file ($SIZE)"
            fi
        fi
    done
fi

if [ ${#FOUND_LOCATIONS[@]} -eq 0 ] && [ -z "$ADDITIONAL_FILES" ]; then
    echo "No Spotify-related files found. Spotify may already be removed."
    exit 0
fi

echo ""
echo "Total locations to remove: ${#FOUND_LOCATIONS[@]}"
echo ""
echo "WARNING: This will permanently delete all Spotify data and cannot be undone."
echo "You will need to reinstall Spotify and log in again if you want to use it later."
echo ""
read -p "Do you want to proceed? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Aborted."
    exit 0
fi

echo ""
echo "Removing Spotify files..."

REMOVED_COUNT=0
FAILED_COUNT=0

# Remove all found locations
for location in "${SPOTIFY_LOCATIONS[@]}"; do
    if [ -e "$location" ]; then
        echo "Removing: $location"
        if rm -rf "$location" 2>/dev/null; then
            REMOVED_COUNT=$((REMOVED_COUNT + 1))
        else
            echo "  Warning: Failed to remove $location (may require sudo)"
            FAILED_COUNT=$((FAILED_COUNT + 1))
        fi
    fi
done

# Remove additional files found
if [ -n "$ADDITIONAL_FILES" ]; then
    echo "$ADDITIONAL_FILES" | while read -r file; do
        if [ -e "$file" ]; then
            echo "Removing: $file"
            if rm -rf "$file" 2>/dev/null; then
                REMOVED_COUNT=$((REMOVED_COUNT + 1))
            else
                echo "  Warning: Failed to remove $file (may require sudo)"
                FAILED_COUNT=$((FAILED_COUNT + 1))
            fi
        fi
    done
fi

echo ""
echo "=== Cleanup Complete ==="
echo ""
echo "Removed: $REMOVED_COUNT location(s)"
if [ $FAILED_COUNT -gt 0 ]; then
    echo "Failed: $FAILED_COUNT location(s) (may require sudo privileges)"
fi
echo ""

# Final verification
REMAINING=$(find "$HOME/Library/Preferences" "$HOME/Library/Caches" "$HOME/Library/Containers" "$HOME/Library/Group Containers" "$HOME/Library/Saved Application State" "$HOME/Library/Application Support" "$HOME/Library/Logs" -name "*spotify*" -o -name "*Spotify*" 2>/dev/null | grep -v "^$" || true)

if [ -n "$REMAINING" ]; then
    echo "Warning: Some Spotify files may still remain:"
    echo "$REMAINING"
    echo ""
    echo "These may require sudo privileges to remove. You can try:"
    echo "  sudo rm -rf [file_path]"
else
    echo "✓ All Spotify files have been removed successfully!"
fi

echo ""
echo "Next steps:"
echo "  1. Empty your Trash to permanently delete the files"
echo "  2. If you want to reinstall Spotify, download it from spotify.com"
echo ""
