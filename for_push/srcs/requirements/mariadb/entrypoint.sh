#!/bin/bash

set -eu

if [ -f init.sql.template ]; then
	envsubst < /docker-entrypoint-initdb.b/init.sql.template > /etc/mysql/init.sql
	rm -f init.sql.template
fi

exec "$@"
