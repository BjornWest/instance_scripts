#!/bin/bash

# Script to update nginx configuration and restart nginx
# Usage: ./update_nginx.sh

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/nginx_vllm.conf"
NGINX_CONFIG="/etc/nginx/sites-enabled/vllm_lb"

echo "Updating nginx configuration..."

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Config file not found: $CONFIG_FILE"
    exit 1
fi

# Copy config to nginx sites-enabled
echo "Copying $CONFIG_FILE to $NGINX_CONFIG..."
cp "$CONFIG_FILE" "$NGINX_CONFIG"

# Test nginx configuration
echo "Testing nginx configuration..."
if ! nginx -t; then
    echo "Error: Nginx configuration test failed!"
    exit 1
fi

# Reload or restart nginx
echo "Reloading nginx..."
if systemctl is-active --quiet nginx; then
    systemctl reload nginx
    echo "Nginx reloaded successfully"
else
    echo "Nginx not running, starting it..."
    systemctl start nginx
    echo "Nginx started successfully"
fi

# Verify nginx is running
sleep 1
if systemctl is-active --quiet nginx; then
    echo "✓ Nginx is running"
    echo "✓ Listening on port 80"
    systemctl status nginx --no-pager | head -5
else
    echo "Error: Nginx failed to start!"
    exit 1
fi

echo "Done!"

