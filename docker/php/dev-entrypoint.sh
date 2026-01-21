#!/bin/bash
set -e

# Start PHP-FPM in background
php-fpm -D

# Install npm dependencies if needed
# Check if node_modules is empty or package.json is newer
if [ ! -d "node_modules" ] || [ -z "$(ls -A node_modules 2>/dev/null)" ] || [ "package.json" -nt "node_modules" ]; then
    echo "📦 Installing npm dependencies..."
    npm install
else
    echo "✅ npm dependencies already installed"
fi

# Start Vite dev server
exec npm run dev -- --host 0.0.0.0
