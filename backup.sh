#!/bin/bash

# deze comments zijn voor toekomstige referenties
# of als er iets mis gaat met de backup

# dir's
SOURCE_DIR="/srv/www" # hier maakt die een backup van
BACKUP_ROOT="/mnt/backup" # hier komen de backups

# date variabelen voor de naam van de backups
CURRENT_DATE=$(date +"%Y-%m-%d")
CURRENT_TIME=$(date +"%H-%M-%S")
CURRENT_WEEK=$(date +"%Y-W%U")
CURRENT_MONTH=$(date +"%Y-%m")
CURRENT_YEAR=$(date +"%Y")

# maken van de backup directories
mkdir -p "$BACKUP_ROOT/hourly"
mkdir -p "$BACKUP_ROOT/daily"
mkdir -p "$BACKUP_ROOT/weekly"
mkdir -p "$BACKUP_ROOT/monthly"
mkdir -p "$BACKUP_ROOT/yearly"

## checks voor de directories
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
## einde checks

# Uurlijkse backup(een keer per uur)
tar -czf "$BACKUP_ROOT/hourly/backup-$CURRENT_DATE-$CURRENT_TIME.tar.gz" -C "$SOURCE_DIR" .

# Dagelijkse backup(een keer per dag)
if [ ! -f "$BACKUP_ROOT/daily/backup-$CURRENT_DATE.tar.gz" ]; then
    tar -czf "$BACKUP_ROOT/daily/backup-$CURRENT_DATE.tar.gz" -C "$SOURCE_DIR" .
fi

# Wekelijkse backup(een keer per week)
if [ ! -f "$BACKUP_ROOT/weekly/backup-$CURRENT_WEEK.tar.gz" ]; then
    tar -czf "$BACKUP_ROOT/weekly/backup-$CURRENT_WEEK.tar.gz" -C "$SOURCE_DIR" .
fi

# Maandelijkse backup(een keer per maand)
if [ ! -f "$BACKUP_ROOT/monthly/backup-$CURRENT_MONTH.tar.gz" ]; then
    tar -czf "$BACKUP_ROOT/monthly/backup-$CURRENT_MONTH.tar.gz" -C "$SOURCE_DIR" .
fi

# Jaarlijkse backup(een keer per jaar)
if [ ! -f "$BACKUP_ROOT/yearly/backup-$CURRENT_YEAR.tar.gz" ]; then
    tar -czf "$BACKUP_ROOT/yearly/backup-$CURRENT_YEAR.tar.gz" -C "$SOURCE_DIR" .
fi


# Hou 24 versies van de laatste uur backups
find "$BACKUP_ROOT/hourly" -mindepth 1 -maxdepth 1 -type f | sort | head -n -24 | xargs -r rm -f

# hou alleen 7 versies van de laatste dag backups
find "$BACKUP_ROOT/daily" -mindepth 1 -maxdepth 1 -type f | sort | head -n -7 | xargs -r rm -f

# hou alleen 52 versies van de laatste week backups
find "$BACKUP_ROOT/weekly" -mindepth 1 -maxdepth 1 -type f | sort | head -n -52 | xargs -r rm -f

# hou alleen 12 versies van de laatste maand backups
find "$BACKUP_ROOT/monthly" -mindepth 1 -maxdepth 1 -type f | sort | head -n -12 | xargs -r rm -f

# hou alleen 10 versies van de laatste jaar backups
# uncomment de regel hieronder om de backup liemiet toe te passen
#find "$BACKUP_ROOT/yearly" -mindepth 1 -maxdepth 1 -type f | sort | head -n -10 | xargs -r rm -f
