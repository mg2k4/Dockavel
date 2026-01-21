#!/bin/bash
set -e

echo "Waiting for Laravel to be ready..."
until php /usr/src/app/artisan config:cache >/dev/null 2>&1; do
  sleep 3
done

echo "Laravel ready, starting supervisor..."
exec supervisord -c /etc/supervisor/supervisord.conf
