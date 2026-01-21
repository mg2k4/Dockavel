# 📜 Scripts Reference

Quick reference for all automation scripts.

---

## Overview

| Script | Purpose | When to Use |
|--------|---------|-------------|
| `deploy.sh` | Deploy app (dev/prod) | First deploy, major updates |
| `server-setup.sh` | Initialize server | Once per server (as root) |
| `update.sh` | Quick updates | After git pull |
| `backup.sh` | Database backup | Daily (cron recommended) |
| `laravel-helper.sh` | Laravel commands | Interactive menu |
| `create-ssl-certs.sh` | Dev SSL certificates | Once for local dev |

---

## deploy.sh

Main deployment script for dev and production.

**Usage:**
```bash
chmod +x ./scripts/*.sh   # First time only
./scripts/deploy.sh dev   # Development
./scripts/deploy.sh prod  # Production
```

**What it does:**
1. Checks prerequisites (Docker, Git)
2. Configures environment (interactive prompts)
3. Detects Cloudflare setup
4. Builds and starts Docker containers
5. Installs dependencies (Composer, NPM)
6. Generates APP_KEY
7. Runs database migrations
8. Sets up SSL (prod only)
9. Optimizes Laravel caches

**First run:** Takes 3-5 minutes
**Subsequent runs:** Faster (cached layers)

---

## server-setup.sh

One-time server initialization with security hardening.

**Usage:**
```bash
# On fresh Ubuntu server (as root)
curl -fsSL https://raw.githubusercontent.com/mg2k4/Dockavel/main/scripts/server-setup.sh -o server-setup.sh
chmod +x server-setup.sh
sudo ./server-setup.sh
```

**What it does:**
1. Updates system packages
2. Installs Docker + Docker Compose
3. Configures UFW firewall (ports 22, 80, 443)
4. Sets up Fail2Ban for SSH protection
5. Creates `deploy` user with sudo access
6. Enables automatic security updates
7. Hardens SSH (disables root login, password auth)

**Duration:** ~5 minutes

**After running:** SSH as `deploy` user, not root

---

## update.sh

Quick updates after pulling new code.

**Usage:**
```bash
cd /var/www/app
git pull origin main
./scripts/update.sh
```

**What it does:**
1. Rebuilds containers if Dockerfile changed
2. Installs new dependencies
3. Runs new migrations
4. Clears and rebuilds caches
5. Restarts services

**Note:** Only rebuilds what changed (fast updates)

---

## backup.sh

Database backup with automatic retention.

**Usage:**
```bash
./scripts/backup.sh
```

**What it does:**
1. Creates timestamped SQL dump
2. Saves to `./backups/` directory
3. Compresses with gzip
4. Keeps last 7 daily backups
5. Keeps last 4 weekly backups
6. Removes older backups

**Backup location:** `./backups/db_backup_YYYY-MM-DD_HH-MM-SS.sql.gz`

**Automate with cron:**
```bash
# Daily at 2 AM
0 2 * * * cd /var/www/app && ./scripts/backup.sh >> /var/log/backup.log 2>&1
```

**Restore a backup:**
```bash
gunzip backups/db_backup_2025-01-10_02-00-00.sql.gz
docker compose exec -T db mysql -u root -p${MYSQL_ROOT_PASSWORD} ${DB_DATABASE} < backups/db_backup_2025-01-10_02-00-00.sql
```

---

## laravel-helper.sh

Interactive menu for common Laravel commands.

**Usage:**
```bash
./scripts/laravel-helper.sh
```

**Menu options:**
1. Run migrations
2. Rollback migrations
3. Seed database
4. Clear all caches
5. Run queue worker
6. Start Horizon
7. Run Tinker
8. Generate APP_KEY
9. Storage link
10. Run tests
11. Custom Artisan command

**Shortcut:** Instead of typing `docker compose exec app php artisan migrate`, just run the helper and choose option 1.

---

## create-ssl-certs.sh

Generate self-signed SSL certificates for local development.

**Usage:**
```bash
./scripts/create-ssl-certs.sh
```

**What it does:**
1. Creates `docker/nginx/dev-cert/` directory
2. Generates self-signed certificate (valid 365 days)
3. Configures for localhost

**Note:** Browser will show "Not Secure" warning (normal for self-signed certs)

**Trust the certificate (optional):**
- **Mac:** Add to Keychain, set to "Always Trust"
- **Linux:** Add to system certificates
- **Windows:** Import to "Trusted Root Certification Authorities"

---

## Common Tasks

**Deploy to production:**
```bash
ssh deploy@your-server
cd /var/www/app
chmod +x ./scripts/*.sh      # First time only
./scripts/deploy.sh prod
```

**Update production:**
```bash
ssh deploy@your-server
cd /var/www/app
git pull origin main
./scripts/update.sh
```

**Backup database:**
```bash
./scripts/backup.sh
```

**Run migrations:**
```bash
./scripts/laravel-helper.sh  # Choose option 1
# Or directly:
docker compose exec app php artisan migrate
```

**View logs:**
```bash
docker compose logs -f
docker compose logs -f app  # Just app container
```

---

**Troubleshooting scripts?** See [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
