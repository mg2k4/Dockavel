# 🔧 Troubleshooting

## ⚡ One-Liner Diagnostics

```bash
# Run this first to get a quick health overview
docker compose ps && echo "---" && docker compose exec app php artisan about --only=environment
```

## 🚨 Quick Fixes

### Something broke? Try this first:

```bash
# 1. Clear caches
docker compose exec app php artisan config:clear
docker compose exec app php artisan cache:clear

# 2. Fix permissions
docker compose exec app chown -R www-data:www-data storage bootstrap/cache
docker compose exec app chmod -R 775 storage bootstrap/cache

# 3. Restart
docker compose restart

# 4. Still broken? Check logs
docker compose logs app --tail=50
```

## 📋 Common Issues

### "Port already in use"
```bash
sudo lsof -i :80
sudo kill -9 <PID>
```

### "Permission denied" when running scripts
```bash
chmod +x ./scripts/*.sh
```

### "Database connection refused"
```bash
# Check .env: DB_HOST=db (not localhost!)
docker compose restart db
```

### "502 Bad Gateway"
```bash
docker compose restart app webserver
```

### "SSL certificate failed"
```bash
# Check DNS points to your server
dig +short your-domain.com

# Ensure ports 80/443 are open
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

## 🔍 Still stuck?

**Run diagnostics:**
```bash
docker compose ps             # Check status
docker compose logs           # Check logs
./scripts/laravel-helper.sh   # Interactive helper
```

**Need help?** [Open an issue](https://github.com/mg2k4/Dockavel/issues) with:
- Error message
- Output of `docker compose logs`
- What you tried already
