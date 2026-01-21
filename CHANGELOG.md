# Changelog

All notable changes to Dockavel will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2026-01-19

Initial public release of Dockavel — production-ready Docker environment for Laravel 12+.

### Features

**Automation Scripts:**
- `deploy.sh` — One-command deployment for dev and production
- `server-setup.sh` — Automated server initialization with security hardening
- `update.sh` — Quick application updates after git pull
- `backup.sh` — Database backup with automatic retention
- `laravel-helper.sh` — Interactive menu for common Laravel commands
- `create-ssl-certs.sh` — Self-signed SSL certificates for development

**Docker Stack:**
- PHP 8.4-FPM with OPcache optimization
- Nginx with security headers and rate limiting
- MySQL 8.0 with production tuning
- Redis 7 for cache, sessions, and queues
- Supervisor managing Laravel Horizon
- Automated task scheduler
- Certbot for SSL certificate management

**Security:**
- SSH hardening (key-only auth, root login disabled)
- Fail2Ban protection with automatic IP banning
- UFW firewall configuration (ports 22, 80, 443)
- Automated security updates
- Nginx security headers (HSTS, CSP, X-Frame-Options)
- Protection for sensitive files (.env, .git)

**Additional:**
- Smart Cloudflare detection (proxy vs DNS-only mode)
- Let's Encrypt SSL with auto-renewal
- Health checks on all Docker services
- Hot module replacement with Vite (development)
- Comprehensive documentation

---

[Unreleased]: https://github.com/mg2k4/Dockavel/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/mg2k4/Dockavel/releases/tag/v1.0.0
