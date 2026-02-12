#!/bin/bash

# Time Machine Diagnostic Script
# This script helps diagnose why Time Machine backups are using excessive space

set -e

echo "=== Time Machine Diagnostic Report ==="
echo ""

# Check if Time Machine is enabled
echo "1. Time Machine Status:"
tmutil status | grep -E "(Running|BackupPhase|LastBackupDate|DestinationID)" || echo "  Time Machine may not be configured"
echo ""

# List all mounted volumes
echo "2. All Mounted Volumes (Time Machine may be backing these up):"
df -h | grep -E "^/dev/" | awk '{print $9 " - " $2 " total, " $3 " used, " $4 " available"}'
echo ""

# Check for local snapshots
echo "3. Local Snapshots (stored on internal drive):"
if tmutil listlocalsnapshots / 2>/dev/null | grep -q "com.apple.TimeMachine"; then
    tmutil listlocalsnapshots / | while read -r snapshot; do
        echo "  - $snapshot"
    done
    echo "  Note: Local snapshots can consume significant space"
else
    echo "  No local snapshots found"
fi
echo ""

# Check Time Machine destinations
echo "4. Time Machine Backup Destinations:"
tmutil listdestinations | grep -E "(Name|Kind|URL|ID)" || echo "  No destinations configured"
echo ""

# Check what's excluded from backups
echo "5. Time Machine Exclusions:"
if defaults read /Library/Preferences/com.apple.TimeMachine SkipPaths 2>/dev/null; then
    echo ""
else
    echo "  No system-wide exclusions found"
fi
echo ""

# Check for hidden APFS volumes
echo "6. APFS Volumes (including hidden ones):"
diskutil list | grep -A 20 "APFS" || echo "  No APFS volumes found"
echo ""

# Check actual backup disk usage
echo "7. Backup Disk Usage:"
if [ -d "/Volumes" ]; then
    for vol in /Volumes/*; do
        if [ -d "$vol/.Backups.backupdb" ] || [ -d "$vol/.timemachine" ]; then
            echo "  Found Time Machine backup on: $vol"
            df -h "$vol" | tail -1 | awk '{print "    Total: " $2 ", Used: " $3 ", Available: " $4}'
        fi
    done
fi
echo ""

# Check for large files/directories that might be getting backed up
echo "8. Large Directories on Main Volume (top 10):"
if [ -d "/Users" ]; then
    echo "  Checking /Users (this may take a moment)..."
    du -h -d 1 /Users 2>/dev/null | sort -hr | head -10 || echo "  Could not access /Users"
fi
echo ""

echo "=== Recommendations ==="
echo ""
echo "To get more detailed information:"
echo "  - Run: tmutil listbackups"
echo "  - Check Disk Utility for hidden/mounted volumes"
echo "  - Use 'tmutil compare' to see what changed between backups"
echo "  - Consider using T2M2 utility to analyze backups visually"
echo ""
echo "To check actual unique size of a backup (not hard-link inflated):"
echo "  - Run: tmutil uniquesize /Volumes/[BackupVolume]/.Backups.backupdb/[ComputerName]/[BackupDate]/"
echo ""
