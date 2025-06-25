#!/bin/bash

# These comments are for future reference

# dir's
SOURCE_DIR="" 
BACKUP_ROOT=""

# Date Variables for the backup names
CURRENT_DATE=$(date +"%Y-%m-%d")
CURRENT_TIME=$(date +"%H-%M-%S")
CURRENT_WEEK=$(date +"%Y-W%U")
CURRENT_MONTH=$(date +"%Y-%m")
CURRENT_YEAR=$(date +"%Y")

# creating backup dir
mkdir -p "$BACKUP_ROOT/hourly"
mkdir -p "$BACKUP_ROOT/daily"
mkdir -p "$BACKUP_ROOT/weekly"
mkdir -p "$BACKUP_ROOT/monthly"
mkdir -p "$BACKUP_ROOT/yearly"

## Dir Checks
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Source directory $SOURCE_DIR does not exist. Exiting."
    exit 1
fi

if [ ! -w "$BACKUP_ROOT" ]; then
    echo "Backup root directory $BACKUP_ROOT is not writable. Exiting."
    exit 1
fi

if [ ! -w "$BACKUP_ROOT/hourly" ] || [ ! -w "$BACKUP_ROOT/daily" ] || [ ! -w "$BACKUP_ROOT/weekly" ] || [ ! -w "$BACKUP_ROOT/monthly" ] || [ ! -w "$BACKUP_ROOT/yearly" ]; then
    echo "One or more backup directories are not writable. Exiting."
    exit 1
fi
## End Checks

# Hourly Backup
tar -czf "$BACKUP_ROOT/hourly/backup-$CURRENT_DATE-$CURRENT_TIME.tar.gz" -C "$SOURCE_DIR" .

# Daily Backup
if [ ! -f "$BACKUP_ROOT/daily/backup-$CURRENT_DATE.tar.gz" ]; then
    tar -czf "$BACKUP_ROOT/daily/backup-$CURRENT_DATE.tar.gz" -C "$SOURCE_DIR" .
fi

# Weekly Backup
if [ ! -f "$BACKUP_ROOT/weekly/backup-$CURRENT_WEEK.tar.gz" ]; then
    tar -czf "$BACKUP_ROOT/weekly/backup-$CURRENT_WEEK.tar.gz" -C "$SOURCE_DIR" .
fi

# Monthly Backup
if [ ! -f "$BACKUP_ROOT/monthly/backup-$CURRENT_MONTH.tar.gz" ]; then
    tar -czf "$BACKUP_ROOT/monthly/backup-$CURRENT_MONTH.tar.gz" -C "$SOURCE_DIR" .
fi

# Yearly Backup
if [ ! -f "$BACKUP_ROOT/yearly/backup-$CURRENT_YEAR.tar.gz" ]; then
    tar -czf "$BACKUP_ROOT/yearly/backup-$CURRENT_YEAR.tar.gz" -C "$SOURCE_DIR" .
fi


# Keep 24 hourly backups
find "$BACKUP_ROOT/hourly" -mindepth 1 -maxdepth 1 -type f | sort | head -n -24 | xargs -r rm -f

# Keep 7 daily backups
find "$BACKUP_ROOT/daily" -mindepth 1 -maxdepth 1 -type f | sort | head -n -7 | xargs -r rm -f

# Keep 52 weekly backups
find "$BACKUP_ROOT/weekly" -mindepth 1 -maxdepth 1 -type f | sort | head -n -52 | xargs -r rm -f

# Keep 12 monthly backups
find "$BACKUP_ROOT/monthly" -mindepth 1 -maxdepth 1 -type f | sort | head -n -12 | xargs -r rm -f

# Keep 10 yearly backups
# Uncomment this line below to set limit of 10
#find "$BACKUP_ROOT/yearly" -mindepth 1 -maxdepth 1 -type f | sort | head -n -10 | xargs -r rm -f
