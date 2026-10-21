FROM debian:bookworm

RUN mkdir -p /run/mysqld \
	&& chown -R mysql:mysql /run/mysqld \
	&& mkdir -p /etc/mysql

RUN apt update -y && apt upgrade -y \
	&& apt install -y mariadb-server mariadb-client gettext-base

COPY ./50-server.cnf /etc/mysql/mariadb.conf.d/
COPY ./init.sql.template /docker-entrypoint-initdb.b/
COPY ./entrypoint.sh .
RUN chmod +x ./entrypoint.sh

EXPOSE 3306

LABEL version="11.8"
LABEL description="MariaDB_Server"

ENTRYPOINT [ "./entrypoint.sh" ]
CMD [ "mysqld" ]
