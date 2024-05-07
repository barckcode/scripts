#!/bin/bash
# Description: MySQL Backup
#
#
######################################### Vars:
USER=$1
PASSWORD=$2
# If databases have a prefix:
DATABASES=$(mysql -u $USER -p$PASSWORD -e "SHOW DATABASES LIKE '$3%';" 2>/dev/null | grep -v Database)
S3_BUCKET=$4
TMP_BACKUP_DIR="/tmp/mysql_backups"
DATE=$(date +%d_%m_%Y)


######################################### Script:
mkdir -p $TMP_BACKUP_DIR

# Backup
for db in $DATABASES; do
    echo "Respaldo de la base de datos $db"
    mysqldump -u $USER -p$PASSWORD --databases $db > "$TMP_BACKUP_DIR/${db}.sql"
done

# Upload to S3
aws s3 sync $TMP_BACKUP_DIR $S3_BUCKET/$DATE/

# Clean local backups
rm -rf $TMP_BACKUP_DIR
