#!/bin/bash

# Cleanup Time Machine Interrupted Backups
# This script removes interrupted backup directories to free up space

set -e

BACKUP_DRIVE="/Volumes/Time Machine (SSD)"

if [ ! -d "$BACKUP_DRIVE" ]; then
    echo "Error: Backup drive not found at $BACKUP_DRIVE"
    exit 1
fi

echo "=== Time Machine Interrupted Backup Cleanup ==="
echo ""
echo "This script will remove interrupted backup directories from:"
echo "  $BACKUP_DRIVE"
echo ""

cd "$BACKUP_DRIVE"

echo "Found interrupted backups:"
ls -1d *.interrupted *.inprogress 2>/dev/null | while read -r dir; do
    if [ -d "$dir" ]; then
        echo "  - $dir"
    fi
done

INTERRUPTED_COUNT=$(ls -1d *.interrupted *.inprogress 2>/dev/null | wc -l | tr -d ' ')

if [ "$INTERRUPTED_COUNT" -eq 0 ]; then
    echo ""
    echo "No interrupted backups found. Nothing to clean up."
    exit 0
fi

echo ""
echo "Total interrupted backups: $INTERRUPTED_COUNT"
echo ""
echo "WARNING: This will permanently delete these interrupted backup directories."
echo "Only the current in-progress backup will be preserved if it's actually running."
echo ""
read -p "Do you want to proceed? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Aborted."
    exit 0
fi

echo ""
echo "Removing interrupted backups..."

# Check if there's a currently running backup
CURRENT_BACKUP=$(tmutil status 2>/dev/null | grep -o 'BackupPhase = [^;]*' | cut -d' ' -f3 || echo "")

if [ "$CURRENT_BACKUP" = "Copying" ] || [ "$CURRENT_BACKUP" = "ThinningPreBackup" ]; then
    echo "Warning: A backup is currently running. Only removing .interrupted directories."
    sudo rm -rf *.interrupted 2>/dev/null || true
    echo "Removed .interrupted directories."
else
    echo "No active backup detected. Removing all interrupted and in-progress directories."
    sudo rm -rf *.interrupted *.inprogress 2>/dev/null || true
    echo "Removed interrupted and in-progress backup directories."
fi

echo ""
echo "Cleanup complete!"
echo ""
echo "Remaining backups:"
ls -1d *.previous 2>/dev/null | while read -r dir; do
    echo "  - $dir (previous successful backup)"
done

echo ""
echo "Next steps:"
echo "  1. Check available space: df -h \"$BACKUP_DRIVE\""
echo "  2. Let Time Machine complete a full backup"
echo "  3. Consider excluding system directories if not needed:"
echo "     sudo tmutil addexclusion /Applications"
echo "     sudo tmutil addexclusion /Library"
echo "     sudo tmutil addexclusion /private"
