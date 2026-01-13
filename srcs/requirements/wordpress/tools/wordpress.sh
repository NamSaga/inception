#!/bin/bash

WORDPRESS_DIR="/var/www/html"

# Create required directories
mkdir -p /run/php

# Wait for MariaDB to be ready
echo "Waiting for MariaDB to be ready..."
for i in {1..60}; do
    if mariadb -h"mariadb" -u"$WORDPRESS_DB_USER" -p"$WORDPRESS_DB_PASSWORD" -e "SELECT 1" &>/dev/null; then
        echo "MariaDB is ready!"
        break
    fi
    echo "Waiting for MariaDB... ($i/60)"
    sleep 2
done

# Download and install WordPress if not already present
if [ ! -f "$WORDPRESS_DIR/wp-config.php" ]; then
    echo "Installing WordPress..."
    
    # Download WordPress
    cd /tmp
    wget -q https://wordpress.org/latest.tar.gz
    tar -xzf latest.tar.gz
    cp -r wordpress/* "$WORDPRESS_DIR/"
    rm -rf /tmp/wordpress /tmp/latest.tar.gz
    
    # Create wp-config.php
    cat > "$WORDPRESS_DIR/wp-config.php" <<EOF
<?php
define('DB_NAME', '$WORDPRESS_DB_NAME');
define('DB_USER', '$WORDPRESS_DB_USER');
define('DB_PASSWORD', '$WORDPRESS_DB_PASSWORD');
define('DB_HOST', 'mariadb:3306');
define('DB_CHARSET', 'utf8');
define('DB_COLLATE', '');

define('AUTH_KEY',         'put your unique phrase here');
define('SECURE_AUTH_KEY',  'put your unique phrase here');
define('LOGGED_IN_KEY',    'put your unique phrase here');
define('NONCE_KEY',        'put your unique phrase here');
define('AUTH_SALT',        'put your unique phrase here');
define('SECURE_AUTH_SALT', 'put your unique phrase here');
define('LOGGED_IN_SALT',   'put your unique phrase here');
define('NONCE_SALT',       'put your unique phrase here');

\$table_prefix = 'wp_';

define('WP_DEBUG', false);

if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', dirname( __FILE__ ) . '/' );
}

require_once( ABSPATH . 'wp-settings.php' );
?>
EOF
    
    # Install WordPress using wp-cli
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x wp-cli.phar
    mv wp-cli.phar /usr/local/bin/wp
    
    cd "$WORDPRESS_DIR"
    wp core install \
        --url="$WORDPRESS_URL" \
        --title="$WORDPRESS_URL" \
        --admin_user="$WORDPRESS_ADMIN_USER" \
        --admin_password="$WORDPRESS_ADMIN_PASSWORD" \
        --admin_email="$WORDPRESS_ADMIN_EMAIL" \
        --skip-email \
        --allow-root || true
    
    # Create regular user
    wp user create "$WORDPRESS_USER" "$WORDPRESS_USER_EMAIL" \
        --user_pass="$WORDPRESS_USER_PASSWORD" \
        --role=subscriber \
        --allow-root || true
fi

# Set permissions - world readable/writable for host cleanup
chown -R www-data:www-data "$WORDPRESS_DIR"
chmod -R 777 "$WORDPRESS_DIR"

# Start PHP-FPM in foreground
exec php-fpm7.4 -F
