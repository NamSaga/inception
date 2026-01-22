#!/bin/bash

echo "Starting MariaDB init script..."

if [ -f /run/secrets/mysql_root_password ]; then
    MYSQL_ROOT_PASSWORD=$(cat /run/secrets/mysql_root_password)
fi
if [ -f /run/secrets/mysql_admin_password ]; then
    MYSQL_ADMIN_PASSWORD=$(cat /run/secrets/mysql_admin_password)
fi
if [ -f /run/secrets/mysql_password ]; then
    MYSQL_PASSWORD=$(cat /run/secrets/mysql_password)
fi

echo "MYSQL_DATABASE: $MYSQL_DATABASE"
echo "MYSQL_USER: $MYSQL_USER"

mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld

chown -R mysql:mysql /var/lib/mysql
chmod -R 777 /var/lib/mysql

NEED_INIT=false

if [ ! -d /var/lib/mysql/mysql ]; then
	NEED_INIT=true
	echo "Initializing database..."
	mysql_install_db --user=mysql --datadir=/var/lib/mysql
fi

echo "Starting temporary MariaDB server..."
mariadbd --user=mysql --datadir=/var/lib/mysql --skip-networking &
pid="$!"

for i in {1..30}; do
	if mariadb -u root -e "SELECT 1" &>/dev/null; then
		echo "MariaDB started successfully"
		break
	fi
	echo "Waiting for MariaDB to start... ($i/30)"
	sleep 1
done

DB_EXISTS=$(mariadb -u root -N -e "SHOW DATABASES LIKE '$MYSQL_DATABASE';" 2>/dev/null)

if [ "$NEED_INIT" = true ] || [ -z "$DB_EXISTS" ]; then
	echo "Configuring database..."
	mariadb -u root <<-EOSQL
		DELETE FROM mysql.user WHERE User='';
		DROP DATABASE IF EXISTS test;
		DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%';
		FLUSH PRIVILEGES;
	EOSQL

	if [ -n "$MYSQL_DATABASE" ]; then
		echo "Creating database: $MYSQL_DATABASE"
		mariadb -u root -e "CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\`;"
	fi

	if [ -n "$MYSQL_USER" ] && [ -n "$MYSQL_PASSWORD" ]; then
		echo "Creating user: $MYSQL_USER"
		mariadb -u root -e "DROP USER IF EXISTS '$MYSQL_USER'@'%';"
		mariadb -u root -e "CREATE USER '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';"
		if [ -n "$MYSQL_DATABASE" ]; then
			mariadb -u root -e "GRANT ALL PRIVILEGES ON \`$MYSQL_DATABASE\`.* TO '$MYSQL_USER'@'%';"
		fi
		mariadb -u root -e "FLUSH PRIVILEGES;"
	fi

	chmod -R 777 /var/lib/mysql
else
	echo "Database already exists, skipping configuration..."
fi

echo "Stopping temporary server..."
kill "$pid"
wait "$pid" 2>/dev/null || true

echo "Starting MariaDB..."
exec mariadbd --user=mysql --datadir=/var/lib/mysql --bind-address=0.0.0.0
