# 🐳 Docker Architecture

Technical reference for Docker services and configurations.

---

## Stack Overview

**Services:**
- **webserver** (Nginx) — HTTP/HTTPS, reverse proxy to PHP-FPM
- **app** (PHP 8.4-FPM) — Laravel application runtime
- **db** (MySQL 8.0) — Database
- **caching** (Redis 7) — Cache, sessions, queues
- **supervisor** — Background workers (Horizon)
- **scheduler** — Cron jobs (Laravel scheduler)
- **certbot** — SSL certificate management

**Service Flow:**
```
Internet → webserver:80/443 → app (PHP-FPM)
                                ├─→ db (MySQL)
                                └─→ caching (Redis)

certbot → webserver (SSL certificates)
supervisor → app (background jobs)
scheduler → app (cron tasks)
```

---

## Docker Compose Files

**Structure:**
```
docker-compose.yaml       # Base (shared config)
docker-compose.dev.yaml   # Development overrides
docker-compose.prod.yaml  # Production overrides
```

**Development:**
```bash
docker compose -f docker-compose.yaml -f docker-compose.dev.yaml up
```
- Ports exposed (3306, 6379, 5173)
- Debug enabled
- Self-signed SSL
- Vite HMR enabled

**Production:**
```bash
docker compose -f docker-compose.yaml -f docker-compose.prod.yaml up
```
- No exposed ports except 80/443
- Debug disabled
- Let's Encrypt SSL
- HTTPS redirect enabled

---

## Services

### App (PHP-FPM)

**Image:** `php:8.4-fpm`

**Includes:** Composer, Node.js 20, MySQL client

**PHP Extensions:**
- gd, exif, opcache
- pdo_mysql, pcntl, zip, fileinfo
- redis (PECL)

**Configuration:**
- `docker/php/php.ini` — PHP settings
- `docker/php/opcache.dev.ini` — Dev (instant revalidation)
- `docker/php/opcache.prod.ini` — Prod (no revalidation)

---

### Webserver (Nginx)

**Image:** `nginx:alpine`

**Features:**
- Dynamic config via environment variables
- Cloudflare real IP detection
- Gzip compression
- Security headers (HSTS, X-Frame-Options, etc.)
- Rate limiting

**Configuration:**
- `docker/nginx/nginx.conf` — Main config
- `docker/nginx/fpm-ssl.conf` — Site template
- `docker/nginx/fpm-http.conf` — Temporary certs for Let's Encrypt
- `docker/nginx/entrypoint.sh` — Env substitution

---

### Database (MySQL)

**Image:** `mysql:8.0`

**Key Settings:**
```ini
character-set-server=utf8mb4
innodb_buffer_pool_size=256M
slow_query_log=1
long_query_time=2
```

**View slow queries:**
```bash
docker compose exec db tail -f /var/log/mysql/slow.log
```

**Tuning by RAM:**
- 2GB: `innodb_buffer_pool_size=512M`
- 4GB: `innodb_buffer_pool_size=1G`
- 8GB+: `innodb_buffer_pool_size=2G`

Edit `docker/mysql/my.cnf` and restart.

---

### Caching (Redis)

**Image:** `redis:7-alpine`

**Configuration:**
```bash
--appendonly yes              # AOF persistence
--requirepass ${PASSWORD}     # Auth required
--maxmemory 256mb            # Memory limit
--maxmemory-policy allkeys-lru
```

---

### Supervisor

Runs Laravel Horizon for background jobs.

**Configuration:** `docker/supervisor/horizon.conf`

Auto-restarts on failure.

---

### Scheduler

Runs `php artisan schedule:run` every 60 seconds.

---

### Certbot

Renews SSL certificates every 12 hours automatically.

Checks validity, renews if < 30 days remaining.

---

## Network & Volumes

### Network

**Name:** `app_network` (bridge driver)

**Internal DNS:**
```env
DB_HOST=db
REDIS_HOST=caching
```

Services communicate by name within the network.

### Volumes

**Persistent:**
- `mysql-data` — Database files
- `redis-data` — Cache persistence

**Bind Mounts:**
- `.:/usr/src/app` — Application code
- `./logs/nginx:/var/log/nginx` — Logs
- `./data/certbot/conf:/etc/letsencrypt` — Certificates

---

## Configuration

### PHP (docker/php/php.ini)

```ini
memory_limit=256M
upload_max_filesize=20M
post_max_size=25M
max_execution_time=60
```

### OPcache

**Development:** Validates every request
```ini
opcache.validate_timestamps=1
opcache.revalidate_freq=0
```

**Production:** Never checks (faster)
```ini
opcache.validate_timestamps=0
```

After code changes: `docker compose restart app`

### MySQL (docker/mysql/my.cnf)

Default config is production-ready for 2-4GB RAM servers.

For tuning: edit `docker/mysql/my.cnf` and restart db service.

---

## Customization

### Add PHP Extension

Edit `docker/php/Dockerfile`:
```dockerfile
RUN apt-get install -y libmagickwand-dev \
    && pecl install imagick \
    && docker-php-ext-enable imagick
```

Rebuild: `docker compose build --no-cache app && docker compose up -d`

### Add Service

Add to `docker-compose.yaml`:
```yaml
services:
  newservice:
    image: service/image
    networks:
      - app_network
    volumes:
      - newservice-data:/data
```

### Resource Limits

Uncomment in `docker-compose.yaml`:
```yaml
deploy:
  resources:
    limits:
      cpus: '2'
      memory: 2G
```

Useful when running multiple apps on same server.

---

## Production Checklist

**Before going live:**

1. ✅ Run `server-setup.sh` (configures firewall, Fail2Ban, security)
2. ✅ Set strong passwords in `.env` (`openssl rand -base64 32`)
3. ✅ Set up automated backups (`crontab -e` → add `backup.sh`)
4. ✅ Test SSL certificate renewal (`docker compose exec certbot certbot renew --dry-run`)
5. ✅ Enable resource limits if needed (edit `docker-compose.yaml`)
6. ✅ Configure log rotation (`/etc/logrotate.d/`)

**Post-launch:**
- Monitor logs: `docker compose logs -f`
- Check health: `docker compose ps`
- Monitor disk space: `df -h`

---

For common commands, see [README.md](../README.md#-common-commands).

For troubleshooting, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md).
