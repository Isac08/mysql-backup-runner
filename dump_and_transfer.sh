#!/bin/bash
set -Eeuo pipefail
trap 'send_discord_alert "Error at line $LINENO: $BASH_COMMAND"' ERR

# Check required variables
: "${DB_HOST:?DB_HOST is required}"
: "${DB_USER:?DB_USER is required}"
: "${DB_PASSWORD:?DB_PASSWORD is required}"
: "${DB_NAME:?DB_NAME is required}"
: "${SCP_TARGET:?SCP_TARGET is required}"
: "${DISCORD_WEBHOOK_URL:?WEBHOOK_URL is required}"

WEBHOOK_URL="$DISCORD_WEBHOOK_URL"
LOG_FILE="/var/log/mysql_backup.log"
TIMESTAMP=$(date +"%Y-%m-%d_%H:%M:%S")
BACKUP_FILE="/backup/backup-${DB_NAME}-${TIMESTAMP}.sql.gz"

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
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# Setup SSH key with correct permissions
SSH_KEY_SOURCE="/root/.ssh"
SSH_KEY_TEMP="/tmp/ssh_key"

# Use specified key or default to id_ed25519
SSH_KEY_NAME="${SSH_PRIVATE_KEY_NAME:-id_ed25519}"
PRIVATE_KEY="$SSH_KEY_SOURCE/$SSH_KEY_NAME"

if [ -f "$PRIVATE_KEY" ]; then
  log "🔑 Using SSH key: $SSH_KEY_NAME"
  cp "$PRIVATE_KEY" "$SSH_KEY_TEMP"
  chmod 600 "$SSH_KEY_TEMP"
else
  log "❌ SSH key not found: $PRIVATE_KEY"
  log "💡INFO: Set SSH_PRIVATE_KEY_NAME in .env if using a different key"
  exit 1
fi

# Add target host to known_hosts to avoid host key verification
TARGET_HOST=$(echo "$SCP_TARGET" | sed 's/.*@//' | sed 's/:.*//')
log "🔑 Adding $TARGET_HOST to known_hosts"
mkdir -p /tmp/.ssh
ssh-keyscan -H "$TARGET_HOST" >> /tmp/.ssh/known_hosts 2>/dev/null || true

# Create log dir
mkdir -p "$(dirname "$LOG_FILE")"

log "📦 Dumping database $DB_NAME from $DB_HOST"
export MYSQL_PWD="$DB_PASSWORD"
mysqldump -h "$DB_HOST" -u "$DB_USER" "$DB_NAME" | gzip > "$BACKUP_FILE"
unset MYSQL_PWD

log "🚚 Sending $(basename "$BACKUP_FILE") to $SCP_TARGET"
scp -i "$SSH_KEY_TEMP" \
    -o UserKnownHostsFile=/tmp/.ssh/known_hosts \
    -o ConnectTimeout=10 \
    -o BatchMode=yes \
    "$BACKUP_FILE" "$SCP_TARGET"

log "✅ Backup and transfer completed!!"

sleep 0.5