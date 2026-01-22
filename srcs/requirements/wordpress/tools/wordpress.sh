#!/bin/bash

WORDPRESS_DIR="/var/www/html"
PHP_FPM_PORT=${PHP_FPM_PORT:-9000}
NGINX_PORT=${NGINX_PORT:-80}
adjust_url_for_port() {
    local url=$1
    local port=$2

    local scheme=$(echo "$url" | grep -o '^[^:]*')
    local host=$(echo "$url" | sed -E 's|^[^:]+://([^:/]+).*|\1|')
    local path=$(echo "$url" | sed -E 's|^[^:]+://[^/]*(/.*)|\1|')
    
    if [ "$path" = "$url" ]; then
        path="/"
    fi

    if [[ "$scheme" == "http" && "$port" != "80" ]] || [[ "$scheme" == "https" && "$port" != "443" ]]; then
        echo "${scheme}://${host}:${port}${path}"
    else
        echo "$url"
    fi
}

if [ -n "$WORDPRESS_URL" ]; then
    WORDPRESS_URL=$(adjust_url_for_port "$WORDPRESS_URL" "$NGINX_PORT")
    echo "Adjusted WordPress URL to: $WORDPRESS_URL"
fi

sed -i "s/PHP_FPM_PORT_PLACEHOLDER/$PHP_FPM_PORT/g" /etc/php/8.2/fpm/pool.d/www.conf


if [ -f /run/secrets/mysql_password ]; then
    WORDPRESS_DB_PASSWORD=$(cat /run/secrets/mysql_password)
fi
if [ -f /run/secrets/wordpress_admin_password ]; then
    WORDPRESS_ADMIN_PASSWORD=$(cat /run/secrets/wordpress_admin_password)
fi
if [ -f /run/secrets/wordpress_user_password ]; then
    WORDPRESS_USER_PASSWORD=$(cat /run/secrets/wordpress_user_password)
fi


mkdir -p /run/php
MARIADB_PORT=${MARIADB_PORT:-3306}
echo "Waiting for MariaDB to be ready on port $MARIADB_PORT..."
for i in {1..60}; do
    if mariadb -h"mariadb" -P"$MARIADB_PORT" -u"$WORDPRESS_DB_USER" -p"$WORDPRESS_DB_PASSWORD" -e "SELECT 1" &>/dev/null; then
        echo "MariaDB is ready!"
        break
    fi
    echo "Waiting for MariaDB... ($i/60)"
    sleep 2
done

if [ ! -f "$WORDPRESS_DIR/wp-config.php" ]; then
    echo "Installing WordPress..."
    
    cd /tmp
    wget -q https://wordpress.org/latest.tar.gz  
    tar -xzf latest.tar.gz
    cp -r wordpress/* "$WORDPRESS_DIR/"
    rm -rf /tmp/wordpress /tmp/latest.tar.gz
    
    cat > "$WORDPRESS_DIR/wp-config.php" <<EOF
<?php
define('DB_NAME', '$WORDPRESS_DB_NAME');
define('DB_USER', '$WORDPRESS_DB_USER');
define('DB_PASSWORD', '$WORDPRESS_DB_PASSWORD');
define('DB_HOST', "mariadb:$MARIADB_PORT");
define('DB_CHARSET', 'utf8');
define('DB_COLLATE', '');


\$table_prefix = 'wp_';

define('WP_DEBUG', false);

if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', dirname( __FILE__ ) . '/' );
}

require_once( ABSPATH . 'wp-settings.php' );
?>
EOF
fi

if [ ! -f /usr/local/bin/wp ]; then
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar  
    chmod +x wp-cli.phar
    mv wp-cli.phar /usr/local/bin/wp
fi

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

    wp user create "$WORDPRESS_USER" "$WORDPRESS_USER_EMAIL" \
        --user_pass="$WORDPRESS_USER_PASSWORD" \
        --role=subscriber \
        --allow-root || true
else
    echo "WordPress is already installed."
    CURRENT_SITE_URL=$(wp option get siteurl --allow-root 2>/dev/null)
    if [ "$CURRENT_SITE_URL" != "$WORDPRESS_URL" ]; then
        echo "Updating WordPress site URL from '$CURRENT_SITE_URL' to '$WORDPRESS_URL'"
        wp option update siteurl "$WORDPRESS_URL" --allow-root
        wp option update home "$WORDPRESS_URL" --allow-root
    fi
fi

chown -R www-data:www-data "$WORDPRESS_DIR"
chmod -R 777 "$WORDPRESS_DIR"

exec php-fpm8.2 -F