#!/bin/bash
set -e 
if [ ! -d /var/lib/mysql/mysql ]; then
	mariadb-install-db --user=mysql --ldata=/var/lib/mysql > /dev/null 2>&1

	mysqld_safe --datadir='/var/lib/mysql' &
	pid="$!"

	sleep 5

	mariadb -u root <<-EOSQL
		DELETE FROM mysql.user WHERE User='';
		DROP DATABASE IF EXISTS test;
		DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%';
		FLUSH PRIVILEGES;
	EOSQL
	if [ ! -z "$MARIADB_DATABASE" ]; then
		mariadb -u root <<-EOSQL
			CREATE DATABASE IF NOT EXISTS \`$MARIADB_DATABASE\` ;
		EOSQL
	fi
	if [ ! -z "$MARIADB_USER" ] && [ ! -z "$MARIADB_PASSWORD" ]; then
		mariadb -u root <<-EOSQL
			CREATE USER '$MARIADB_USER'@'%' IDENTIFIED BY '$MARIADB_PASSWORD' ;
		EOSQL
		if [ ! -z "$MARIADB_DATABASE" ]; then
			mariadb -u root <<-EOSQL
				GRANT ALL PRIVILEGES ON \`$MARIADB_DATABASE\`.* TO '$MARIADB_USER'@'%' ;
			EOSQL
		fi
		mariadb -u root <<-EOSQL
			FLUSH PRIVILEGES ;
		EOSQL
	fi 
	wait "$pid"
fi
chown -R mysql:mysql /var/lib/mysql
exec mysqld_safe --datadir='/var/lib/mysql'
