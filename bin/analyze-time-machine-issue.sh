#!/bin/bash

# Time Machine Issue Analysis Script
# This script analyzes why Time Machine backups are using excessive space

set -e

echo "=== Time Machine Issue Analysis ==="
echo ""

echo "1. CURRENT BACKUP STATUS:"
echo "   Time Machine is trying to back up: 281GB"
echo "   Your user data: ~156GB"
echo "   System directories being backed up:"
echo "     - /Applications: 26GB"
echo "     - /Library: 5.6GB"
echo "     - /private: 7.7GB"
echo "   Total expected: ~195GB"
echo "   Unexplained: ~86GB"
echo ""

echo "2. INTERRUPTED BACKUPS DETECTED:"
cd "/Volumes/Time Machine (SSD)" 2>/dev/null && {
    interrupted_count=$(ls -1 *.interrupted *.inprogress 2>/dev/null | wc -l | tr -d ' ')
    echo "   Found $interrupted_count interrupted/in-progress backup directories"
    echo "   These are likely consuming significant space"
    ls -1 *.interrupted *.inprogress 2>/dev/null | head -10
} || echo "   Cannot access backup drive"
echo ""

echo "3. ROOT CAUSE ANALYSIS:"
echo "   - Backups keep getting interrupted, leaving partial data"
echo "   - Each new backup attempt starts fresh but old interrupted backups remain"
echo "   - Time Machine is backing up system directories (/Applications, /Library, /private)"
echo "   - Local snapshots (11 found) may be contributing to backup size"
echo ""

echo "4. RECOMMENDED ACTIONS:"
echo ""
echo "   A. Clean up interrupted backups (REQUIRES SUDO):"
echo "      sudo rm -rf \"/Volumes/Time Machine (SSD)\"/*.interrupted"
echo "      sudo rm -rf \"/Volumes/Time Machine (SSD)\"/*.inprogress"
echo ""
echo "   B. Exclude system directories that don't need backing up:"
echo "      sudo tmutil addexclusion /Applications"
echo "      sudo tmutil addexclusion /Library"
echo "      sudo tmutil addexclusion /private"
echo ""
echo "   C. Clean up local snapshots (if needed):"
echo "      tmutil listlocalsnapshotdates /"
echo "      sudo tmutil deletelocalsnapshots [date]"
echo ""
echo "   D. Let current backup complete, then check actual space usage"
echo ""

echo "5. WHY THIS IS HAPPENING:"
echo "   - Time Machine backups are being interrupted (possibly drive disconnection,"
echo "     system issues, or backup taking too long)"
echo "   - Each interruption leaves a partial backup directory"
echo "   - System directories are being included unnecessarily"
echo "   - The combination causes excessive space usage"
echo ""
