# Time Machine Excessive Space Usage - Analysis & Solution

## Problem Summary

Time Machine backups are consuming ~1TB on a 2TB drive when only ~150GB of user data exists. Backups appear non-incremental and keep restarting.

## Root Causes Identified

### 1. **Multiple Interrupted Backups (PRIMARY ISSUE)**
- **26 interrupted backup directories** found on the backup drive
- Each interrupted backup leaves partial data that consumes space
- Time Machine keeps starting fresh backups instead of resuming
- This is the main reason for excessive space usage

### 2. **System Directories Being Backed Up**
Time Machine is backing up system directories that may not need backing up:
- `/Applications`: 26GB
- `/Library`: 5.6GB  
- `/private`: 7.7GB
- Total: ~40GB of system files

### 3. **Backup Size Calculation**
- Time Machine reports trying to back up: **281GB**
- User data (`/Users/brett`): **156GB**
- System directories: **~40GB**
- **Unexplained: ~85GB** (possibly local snapshots, caches, or other data)

### 4. **Local Snapshots**
- 11 local snapshots found on internal drive
- These may contribute to backup size calculations

## Why Backups Keep Getting Interrupted

Possible causes:
- External drive disconnection (USB/Thunderbolt issues)
- System going to sleep (though currently prevented by backupd)
- Backup taking too long and timing out
- Drive errors or corruption
- Power management issues

## Solutions

### Immediate Fix: Clean Up Interrupted Backups

Run the cleanup script:
```bash
./bin/cleanup-time-machine-interrupted.sh
```

Or manually:
```bash
sudo rm -rf "/Volumes/Time Machine (SSD)"/*.interrupted
sudo rm -rf "/Volumes/Time Machine (SSD)"/*.inprogress
```

**Warning**: Only do this when no backup is actively running. Check with `tmutil status` first.

### Optimize What Gets Backed Up

Exclude system directories that don't need backing up (these can be reinstalled):
```bash
sudo tmutil addexclusion /Applications
sudo tmutil addexclusion /Library
sudo tmutil addexclusion /private
```

This will reduce backup size from ~281GB to ~156GB (just user data).

### Prevent Future Interruptions

1. **Check drive connection**: Ensure the external drive has a stable connection
2. **Check drive health**: Run `diskutil verifyDisk` on the backup drive
3. **Prevent sleep during backups**: Already configured (sleep prevented by backupd)
4. **Monitor backup logs**: Check `log show --predicate 'subsystem == "com.apple.TimeMachine"' --last 24h` for errors

### Clean Up Local Snapshots (if needed)

If local snapshots are consuming too much space:
```bash
# List snapshots
tmutil listlocalsnapshotdates /

# Delete specific snapshot
sudo tmutil deletelocalsnapshots 2026-01-21-064604
```

## Expected Results After Fix

- Backup size should reduce from ~281GB to ~156GB (if excluding system dirs)
- Only one backup directory should exist (current successful backup)
- Future backups should be truly incremental
- Drive space usage should stabilize

## Diagnostic Commands

```bash
# Check Time Machine status
tmutil status

# List all backups
tmutil listbackups

# Check what's excluded
defaults read /Library/Preferences/com.apple.TimeMachine SkipPaths

# Check backup drive space
df -h "/Volumes/Time Machine (SSD)"

# Analyze backup issue
./bin/analyze-time-machine-issue.sh
```

## Research Findings

Based on online research, this is a known issue where:
- Interrupted backups leave partial data that consumes space
- APFS backups use snapshots which can appear larger than they are
- System directories are included by default and may not need backing up
- Hard links make Finder show inflated sizes, but actual disk usage may be different

## Next Steps

1. ✅ Run cleanup script to remove interrupted backups
2. ✅ Exclude system directories if not needed
3. ✅ Let current backup complete
4. ✅ Monitor next few backups to ensure they're incremental
5. ✅ Check actual disk usage after cleanup: `df -h "/Volumes/Time Machine (SSD)"`
