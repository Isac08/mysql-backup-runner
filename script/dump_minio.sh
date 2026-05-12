#!/bin/bash
set -Eeuo pipefail
trap 'send_discord_alert "Error at line $LINENO: $BASH_COMMAND"' ERR

# Check required variables
: "${DB_HOST:?DB_HOST is required}"
: "${DB_USER:?DB_USER is required}"
: "${DB_PASSWORD:?DB_PASSWORD is required}"
: "${DB_NAME:?DB_NAME is required}"
: "${MINIO_BUCKET:?MINIO_BUCKET is required}"
: "${MINIO_URL:?MINIO_URL is required}"
: "${MINIO_ACCESS_KEY:?MINIO_ACCESS_KEY is required}"
: "${MINIO_SECRET_KEY:?MINIO_SECRET_KEY is required}"
: "${DISCORD_WEBHOOK_URL:?WEBHOOK_URL is required}"

WEBHOOK_URL="$DISCORD_WEBHOOK_URL"
LOG_FILE="/var/log/mysql_backup.log"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_FILE="/backup/backup-${DB_NAME}-${TIMESTAMP}.sql.gz"
BUCKET=${MINIO_BUCKET}
ACCESS_KEY=${MINIO_ACCESS_KEY}
SECRET_KEY=${MINIO_SECRET_KEY}

# func to send alert to discord on failure
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

# func to log the process
log() {
  echo "[$(date '+%Y-%m-%d %H-%M-%S')] $*" | tee -a "$LOG_FILE"
}

# Create log dir
mkdir -p "$(dirname "$LOG_FILE")"

log "📦 Dumping database $DB_NAME from $DB_HOST"
export MYSQL_PWD="$DB_PASSWORD"
mysqldump -h "$DB_HOST" -u "$DB_USER" "$DB_NAME" | gzip > "$BACKUP_FILE"
unset MYSQL_PWD

log "🚚 Sending $(basename "$BACKUP_FILE") to Storage $"
# Configure alias
mc alias set myminio "$MINIO_URL" "$ACCESS_KEY" "$SECRET_KEY"

# Create bucket if not exists
mc mb --ignore-existing myminio/$BUCKET

# Upload file
mc cp "$BACKUP_FILE" myminio/$BUCKET/

log "✅ Backup and transfer completed!!"

sleep 0.5