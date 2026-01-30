#!/bin/bash
set -Eeuo pipefail
trap 'send_discord_alert "Error at line $LINENO: $BASH_COMMAND"' ERR

# Check required variables
: "${DB_HOST:?DB_HOST is required}"
: "${DB_USER:?DB_USER is required}"
: "${DB_PASS:?DB_PASS is required}"
: "${DB_NAME:?DB_NAME is required}"
: "${SCP_TARGET:?SCP_TARGET is required}"
: "${DISCORD_WEBHOOK_URL:?WEBHOOK_URL is required}"

WEBHOOK_URL="$DISCORD_WEBHOOK_URL"
LOG_FILE="/var/log/mysql_backup.log"
TIMESTAMP=$(date +"%Y-%m-%d|%H:%M:%S")
BACKUP_FILE="/backup/backup-${DB_NAME}-${TIMESTAMP}.sql.gz"

send_discord_alert() {
  local MESSAGE="$1"

  jq -n \
    --arg content "🚨 **DB Backup Failed** 🚨
      Time: $TIMESTAMP
      Reason: $MESSAGE" \
    '{content: $content}' |
  curl -s -X POST "$WEBHOOK_URL" \
    -H "Content-Type: application/json" \
    -d @-
}



# Create log dir
mkdir -p "$(dirname "$LOG_FILE")"

# Send stdout + stderr to both the log file and container stdout
exec > >(ts '[%Y-%m-%d %H:%M:%S] ' | tee -a "$LOG_FILE") 2>&1


echo "📦 Dumping database $DB_NAME from $DB_HOST"
export MYSQL_PWD="$DB_PASS"
mysqldump -h "$DB_HOST" -u "$DB_USER" "$DB_NAME" | gzip > "$BACKUP_FILE"
unset MYSQL_PWD

echo "🚚 Sending $BACKUP_FILE to $SCP_TARGET"
#scp -o StrictHostKeyChecking=no "$BACKUP_FILE" "$SCP_TARGET"
scp -o ConnectTimeout=10 -o BatchMode=yes "$BACKUP_FILE" "$SCP_TARGET"

echo "Backup and transfer completed! 🔥"
