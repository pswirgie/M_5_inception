#!/bin/bash
set -eu

mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld /var/lib/mysql

if [ ! -d /var/lib/mysql/mysql ]; then
	mariadb-install-db --user=mysql --datadir=/var/lib/mysql >/dev/null
fi

DB_PASSWORD=$(cat /run/secrets/db_password)
ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
export DB_PASSWORD ROOT_PASSWORD

envsubst < /docker-entrypoint-initdb.d/init.sql.template > /etc/mysql/init.sql

exec "$@"
