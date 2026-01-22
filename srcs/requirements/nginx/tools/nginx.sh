#!/bin/bash

set -e

PHP_FPM_PORT=${PHP_FPM_PORT:-9000}

sed -i "s/PHP_FPM_PORT_PLACEHOLDER/$PHP_FPM_PORT/g" /etc/nginx/sites-available/default

SSL_DIR="/etc/nginx/ssl"
CERT_FILE="$SSL_DIR/certificate.crt"
KEY_FILE="$SSL_DIR/private.key"

mkdir -p "$SSL_DIR"

if [ ! -f "$CERT_FILE" ] || [ ! -f "$KEY_FILE" ]; then
    echo "Generating self-signed SSL certificate..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$KEY_FILE" \
        -out "$CERT_FILE" \
        -subj "/C=FR/ST=State/L=City/O=Organization/CN=rmamisoa.42.fr"
fi

ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default 2>/dev/null || true

nginx -t

exec nginx -g "daemon off;"
