FROM debian:bookworm

RUN apt update -y && apt upgrade -y \
	&& apt install -y mariadb-server mariadb-client gettext-base

COPY ./50-server.cnf /etc/mysql/mariadb.conf.d/ \
	&& mkdir -p /run/mysqld \
	&& chown -R mysql:mysql /run/mysqld
COPY ./init.sql.template .
COPY ./entrypoint.sh .
RUN chmod +x ./entrypoint.sh

EXPOSE 3306

LABEL version="11.8"
LABEL description="MariaDB_Server"

ENTRYPOINT [ "./entrypoint.sh" ]
CMD [ "mysqld" ]
