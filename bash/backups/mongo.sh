#!/bin/bash
# Description: Mongo Backup
#
#
######################################### Vars:
USER=$1
PASSWORD=$2
host=$3
database=$4
S3_BUCKET=$5
TMP_BACKUP_DIR="/tmp/mongo_backups"
DATE=$(date +%d_%m_%Y)

######################################### Script:
mkdir -p $TMP_BACKUP_DIR

# Backup
mongodump --host $host --username $USER --password $PASSWORD --authenticationDatabase $database --out ${TMP_BACKUP_DIR}

# Upload to S3
aws s3 sync $TMP_BACKUP_DIR $S3_BUCKET/$DATE/

# Clean local backups
rm -rf $TMP_BACKUP_DIR
