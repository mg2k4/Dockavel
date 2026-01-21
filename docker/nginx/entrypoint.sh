#!/bin/bash
set -e

: "${SSL_CERT:=/etc/letsencrypt/live/${SERVER_NAME}/fullchain.pem}"
: "${SSL_KEY:=/etc/letsencrypt/live/${SERVER_NAME}/privkey.pem}"

# Check if SSL certificates exist
if [ -f "$SSL_CERT" ] && [ -f "$SSL_KEY" ]; then
    echo "✓ SSL certificates found - enabling HTTPS"
    TEMPLATE="/etc/nginx/fpm-ssl.conf"
else
    echo "○ SSL certificates not found - HTTP only mode"
    TEMPLATE="/etc/nginx/fpm-http.conf"
fi

# Generate config from template
envsubst '$NGINX_ROOT $NGINX_FPM_HOST $NGINX_FPM_PORT $SERVER_NAME $SSL_CERT $SSL_KEY' \
    < "$TEMPLATE" > /etc/nginx/conf.d/default.conf

exec nginx -g "daemon off;"
