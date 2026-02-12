#!/bin/bash

# Fix Time Machine Full Backup Issue
# This script applies the suggested solutions from the analysis:
# 1. Excludes system directories that don't need backing up
# 2. Note: Cleanup of interrupted backups should be done separately when drive is mounted

set -e

echo "=== Time Machine Fix Script ==="
echo ""
echo "This script will:"
echo "  1. Exclude system directories (/Applications, /Library, /private) from backups"
echo "     (These can be reinstalled and don't need backing up)"
echo ""
echo "Note: To clean up interrupted backups, run:"
echo "  ./bin/cleanup-time-machine-interrupted.sh"
echo "  (Requires backup drive to be mounted)"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "This script requires sudo privileges."
    echo "Please run: sudo $0"
    exit 1
fi

echo "Adding exclusions for system directories..."
echo ""

# Add exclusions
echo "Excluding /Applications..."
tmutil addexclusion /Applications

echo "Excluding /Library..."
tmutil addexclusion /Library

echo "Excluding /private..."
tmutil addexclusion /private

echo ""
echo "=== Exclusions Added Successfully ==="
echo ""
echo "Current exclusions:"
defaults read /Library/Preferences/com.apple.TimeMachine SkipPaths | grep -E "(Applications|Library|private)" || echo "  (Note: May not show if using newer exclusion method)"
echo ""
echo "Next steps:"
echo "  1. When your backup drive is mounted, run: ./bin/cleanup-time-machine-interrupted.sh"
echo "  2. Let Time Machine complete the next backup"
echo "  3. Future backups should be incremental and much smaller (~156GB instead of ~281GB)"
echo ""
echo "To verify exclusions were added:"
echo "  tmutil isexcluded /Applications"
echo "  tmutil isexcluded /Library"
echo "  tmutil isexcluded /private"
echo ""
