# mysql-backup-runner

A lightweight Docker-based MySQL backup runner with compression, remote transfer, and Discord failure alerts.

This project provides a production-ready way to automate MySQL backups using a Docker container. It supports database dumping, gzip compression, secure transfer to a remote server, and failure notifications via Discord webhook.

---

## 🚀 Features

* Automated MySQL database dumps
* Gzip compression to reduce backup size
* Transfer backups to a remote server via SCP
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

| Variable              | Description                              |
|-----------------------|------------------------------------------|
| `DB_HOST`             | MySQL host                               |
| `DB_USER`             | MySQL username                           |
| `DB_PASSWORD`         | MySQL user's password                    |
| `DB_NAME`             | Database name to back up                 |
| `SCP_TARGET`          | SCP destination (e.g. `user@host:/path`) |
| `DISCORD_WEBHOOK_URL` | Discord webhook URL for failure alerts   |
| `SSH_PRIVATE_KEY_NAME`          | SSH private key filename inside `/root/.ssh` (default: `id_ed25519`) |
---

## ▶️ Run with Docker

Example using `docker run`:

```bash
docker run --rm \
  -e DB_HOST=127.0.0.1 \
  -e DB_USER=backup_user \
  -e DB_PASSWORD=secret \
  -e DB_NAME=production_db \
  -e SCP_TARGET=backup@server.com:/db-backup \
  -e DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/xxx/yyy \
  -e SSH_PRIVATE_KEY_NAME=my_ssh_key \
  latzzo/mysql-backup-runner:latest
```

---

## ▶️ Run with Docker Compose

When using SCP, the container needs access to SSH credentials. The recommended approach is to **mount your SSH private key and `known_hosts` file as read-only volumes**.

This allows the container to authenticate securely to the remote server **without embedding secrets into the image**.

### SSH requirements

- SSH key-based authentication (no password)
- `known_hosts` file to avoid interactive host verification
- Both mounted as **read-only** volumes

### Example `docker-compose.yml`

```yaml
services:
  mysql-backup:
    image: latzzo/mysql-backup-runner:latest
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
      # Backup output
      - ./backups:/backup

      # Backup logs
      - ./logs:/var/log
      
      # All ssh keys (read-only)
      - ~/.ssh:/root/.ssh/:ro
    restart: "no"

networks:
  db_network: # <-- same network with the database container
    external: true
```

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
