# mysql-backup-runner

A lightweight Docker-based MySQL backup runner with compression, remote transfer, and Discord failure alerts.

This project provides a production-ready way to automate MySQL backups using a Docker container. It supports database dumping, gzip compression, secure transfer to a remote server, and failure notifications via Discord webhook.

---

## 🚀 Features

* Automated MySQL database dumps
* Gzip compression to reduce backup size
* **Multiple Transfer Modes:**
    * Transfer backups to a remote server via SCP
    * Upload backups to MinIO or any S3-compatible storage
* Discord webhook alerts on failure
* Docker & Docker Compose friendly
* Environment-variable–based configuration
* Designed for cron, systemd timers, or container schedulers

---

## 🐳 Docker Image

The image is publicly available on Docker Hub:

```
latzzo/mysql-backup-runner
```

You can pull it directly:

```bash
docker pull latzzo/mysql-backup-runner:latest
```

---

## ⚙️ Required Environment Variables

The container is fully configured using environment variables.

### Common Variables

| Variable              | Description                              |
|-----------------------|------------------------------------------|
| `DB_HOST`             | MySQL host                               |
| `DB_USER`             | MySQL username                           |
| `DB_PASSWORD`         | MySQL user's password                    |
| `DB_NAME`             | Database name to back up                 |
| `DISCORD_WEBHOOK_URL` | Discord webhook URL for failure alerts   |

### SCP Mode Variables

| Variable              | Description                                                          |
|-----------------------|----------------------------------------------------------------------|
| `SCP_TARGET`          | SCP destination (e.g. `user@host:/path`)                             |
| `SSH_PRIVATE_KEY_NAME`| SSH private key filename inside `/root/.ssh` (default: `id_ed25519`) |

### MinIO Mode Variables

| Variable           | Description                                    |
|--------------------|------------------------------------------------|
| `MINIO_URL`        | MinIO/S3 endpoint URL (e.g. `https://s3.com`)  |
| `MINIO_ACCESS_KEY` | MinIO Access Key                               |
| `MINIO_SECRET_KEY` | MinIO Secret Key                               |
| `MINIO_BUCKET`     | Target bucket name                             |
---

## ▶️ Run with Docker

### SCP Mode
```bash
docker run --rm \
  -e DB_HOST=127.0.0.1 \
  -e DB_USER=backup_user \
  -e DB_PASSWORD=secret \
  -e DB_NAME=production_db \
  -e SCP_TARGET=backup@server.com:/db-backup \
  -e DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/xxx/yyy \
  -e SSH_PRIVATE_KEY_NAME=my_ssh_key \
  latzzo/mysql-backup-runner:scp
```

### MinIO Mode
```bash
docker run --rm \
  -e DB_HOST=127.0.0.1 \
  -e DB_USER=backup_user \
  -e DB_PASSWORD=secret \
  -e DB_NAME=production_db \
  -e MINIO_URL=https://minio.example.com \
  -e MINIO_ACCESS_KEY=my_access_key \
  -e MINIO_SECRET_KEY=my_secret_key \
  -e MINIO_BUCKET=backups \
  -e DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/xxx/yyy \
  latzzo/mysql-backup-runner:minio
```

---

## ▶️ Run with Docker Compose

### Example `docker-compose.yml` (SCP)

When using SCP, the container needs access to SSH credentials. The recommended approach is to **mount your SSH private key and `known_hosts` file as read-only volumes**.

```yaml
services:
  mysql-backup:
    image: latzzo/mysql-backup-runner:scp
    container_name: mysql-backup-runner
    environment:
      DB_HOST: 127.0.0.1
      DB_USER: backup_user
      DB_PASSWORD: secret
      DB_NAME: production_db
      SCP_TARGET: backup@1.2.3.4:/data/mysql
      DISCORD_WEBHOOK_URL: https://discord.com/api/webhooks/xxx/yyy
      SSH_PRIVATE_KEY_NAME: my_ssh_key
    volumes:
      - ./backups:/backup
      - ./logs:/var/log
      - ~/.ssh:/root/.ssh/:ro
    restart: "no"
```

### Example `docker-compose.yml` (MinIO)

```yaml
services:
  mysql-backup:
    image: latzzo/mysql-backup-runner:minio
    container_name: mysql-backup-runner
    environment:
      DB_HOST: 127.0.0.1
      DB_USER: backup_user
      DB_PASSWORD: secret
      DB_NAME: production_db
      MINIO_URL: https://minio.example.com
      MINIO_ACCESS_KEY: my_access_key
      MINIO_SECRET_KEY: my_secret_key
      MINIO_BUCKET: backups
      DISCORD_WEBHOOK_URL: https://discord.com/api/webhooks/xxx/yyy
    volumes:
      - ./backups:/backup
      - ./logs:/var/log
    restart: "no"
```

---

### SSH requirements (for SCP mode)

- SSH key-based authentication (no password)
- `known_hosts` file to avoid interactive host verification
- Both mounted as **read-only** volumes

---

## 📦 Backup Output

* Backups are created as `.sql.gz` files
* File name format:

```
backup-<DB_NAME>-YYYYMMDD_HHMMSS.sql.gz
```

---

## ⏰ Scheduling Backups

This image is intended to be run by a scheduler such as:

* `cron`
* `systemd` timer
* Docker cron container
* Kubernetes `CronJob`

Example cron (daily at 02:00):

```cron
0 2 * * * docker run --rm --env-file /path/to/.env latzzo/mysql-backup-runner:latest
or
0 2 * * * docker compose -f /path/to/docker-compose.yml run --rm container-name
```

---

## 🚨 Failure Alerts

If any step fails (dump, compression, or transfer), the container:

* exits immediately
* sends a Discord alert with:

    * timestamp
    * error reason

This ensures backup failures never go unnoticed.

---

## 🔐 Security Notes

* Store secrets using environment variables or Docker secrets
* Protect your `.env` files (`chmod 600 .env`)
* Use SSH key-based authentication for SCP (recommended)

---

## 📄 License

MIT License

---

## 🤝 Contributing

Issues and pull requests are welcome. Feel free to open a discussion if you want to extend this runner (e.g. S3 support, retention policies, multi-database backups).
