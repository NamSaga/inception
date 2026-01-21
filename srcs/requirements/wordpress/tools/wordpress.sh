#!/bin/bash

WORDPRESS_DIR="/var/www/html"

# Read passwords from secret files if available
if [ -f /run/secrets/mysql_password ]; then
    WORDPRESS_DB_PASSWORD=$(cat /run/secrets/mysql_password)
fi
if [ -f /run/secrets/wordpress_admin_password ]; then
    WORDPRESS_ADMIN_PASSWORD=$(cat /run/secrets/wordpress_admin_password)
fi
if [ -f /run/secrets/wordpress_user_password ]; then
    WORDPRESS_USER_PASSWORD=$(cat /run/secrets/wordpress_user_password)
fi

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
fi

# Install wp-cli if not present
if [ ! -f /usr/local/bin/wp ]; then
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x wp-cli.phar
    mv wp-cli.phar /usr/local/bin/wp
fi

# Check if WordPress is already installed in the database
cd "$WORDPRESS_DIR"
if ! wp core is-installed --allow-root 2>/dev/null; then
    echo "Running WordPress installation..."
    wp core install \
        --url="$WORDPRESS_URL" \
        --title="$WORDPRESS_URL" \
        --admin_user="$WORDPRESS_ADMIN_USER" \
        --admin_password="$WORDPRESS_ADMIN_PASSWORD" \
        --admin_email="$WORDPRESS_ADMIN_EMAIL" \
        --skip-email \
        --allow-root

    # Create regular user
    wp user create "$WORDPRESS_USER" "$WORDPRESS_USER_EMAIL" \
        --user_pass="$WORDPRESS_USER_PASSWORD" \
        --role=subscriber \
        --allow-root || true
else
    echo "WordPress is already installed."
fi

# Set permissions - world readable/writable for host cleanup
chown -R www-data:www-data "$WORDPRESS_DIR"
chmod -R 777 "$WORDPRESS_DIR"

# Start PHP-FPM in foreground
exec php-fpm8.2 -F
