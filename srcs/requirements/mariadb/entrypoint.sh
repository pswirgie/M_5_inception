#!/bin/bash
set -eu

mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld /var/lib/mysql

if [ ! -d /var/lib/mysql/mysql ]; then
	mariadb-install-db --user=mysql --datadir=/var/lib/mysql >/dev/null
fi

envsubst < /docker-entrypoint-initdb.d/init.sql.template > /etc/mysql/init.sql

exec "$@"
