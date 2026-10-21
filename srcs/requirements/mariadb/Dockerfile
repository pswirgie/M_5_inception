FROM debian:bookworm

RUN apt update -y && apt upgrade -y \
	&& apt install -y mariadb-server mariadb-client gettext-base

RUN mkdir -p /run/mysqld \
	&& mkdir -p /etc/mysql \
	&& chown -R mysql:mysql /run/mysqld

COPY ./50-server.cnf /etc/mysql/mariadb.conf.d/
COPY ./init.sql.template /docker-entrypoint-initdb.d/
COPY ./entrypoint.sh .
RUN chmod +x ./entrypoint.sh

EXPOSE 3306

LABEL description="MariaDB_Server"

ENTRYPOINT [ "./entrypoint.sh" ]
CMD [ "mysqld" ]
