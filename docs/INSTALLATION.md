# 📦 Installation Guide

Step-by-step guide to get Dockavel running in production or locally.

---

## Prerequisites

**Server (Production):**
- Ubuntu 20.04+ (24.04 recommended)
- 2GB RAM minimum (4GB recommended)
- Root or sudo access
- Domain name pointed to your server

**Local (Development):**
- Docker Desktop (Windows/Mac) or Docker Engine (Linux)
- Git

---

## Quick Start (Production)

### 1. Initial Server Setup

Run once on a fresh Ubuntu server:

```bash
curl -fsSL https://raw.githubusercontent.com/mg2k4/Dockavel/main/scripts/server-setup.sh -o server-setup.sh
chmod +x server-setup.sh
sudo ./server-setup.sh
```

This installs Docker, configures the firewall (UFW), sets up Fail2Ban, and creates a `deploy` user.

**Duration:** ~5 minutes

### 2. Deploy Application

```bash
# SSH as deploy user
ssh deploy@your-server-ip

# Clone and deploy
cd /var/www
git clone git@github.com:mg2k4/Dockavel.git app
cd app
chmod +x ./scripts/*.sh
./scripts/deploy.sh prod
```

The script will:
- Detect your environment (Cloudflare or direct)
- Build Docker containers
- Install dependencies
- Set up SSL with Let's Encrypt
- Run migrations
- Start services

**Duration:** ~3-5 minutes

### 3. Access Your App

```
https://your-domain.com
```

---

## Local Development

```bash
git clone git@github.com:mg2k4/Dockavel.git
cd Dockavel
./scripts/deploy.sh dev
```

Access at:
- `http://localhost` — Main app
- `https://localhost` — HTTPS (self-signed cert)
- `http://localhost:5173` — Vite HMR

---

## SSL Configuration

### Let's Encrypt (DNS-only or no Cloudflare)

Automatic! The deploy script handles everything.

### Cloudflare (Proxied — Orange Cloud)

1. In Cloudflare Dashboard:
   - SSL/TLS → Full (Strict)
   - Create Origin Certificate (15 years)
2. Save certificates:
   ```bash
   # As deploy user
   mkdir -p data/certbot/conf/live/your-domain.com/
   nano data/certbot/conf/live/your-domain.com/fullchain.pem  # Paste origin cert
   nano data/certbot/conf/live/your-domain.com/privkey.pem    # Paste private key
   chmod 600 data/certbot/conf/live/your-domain.com/*.pem
   ```
3. Deploy:
   ```bash
   ./scripts/deploy.sh prod
   ```

---

## Post-Installation

**Update your application:**
```bash
ssh deploy@your-server
cd /var/www/app
git pull origin main
./scripts/update.sh
```

**View logs:**
```bash
docker compose logs -f
docker compose logs -f app    # Just app container
```

**Configure backups:**
```bash
# Automate with cron
crontab -e
# Add: 0 2 * * * cd /var/www/app && ./scripts/backup.sh
```

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) if you encounter any issues.

---

## Next Steps

- **Configure your app:** Edit `.env` for mail, queues, etc.
- **Set up monitoring:** Add your preferred monitoring tools
- **Configure backups:** Automate `backup.sh` with cron
- **Review security:** Check [DOCKER.md](DOCKER.md) for hardening tips
