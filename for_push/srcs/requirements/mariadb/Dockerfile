FROM debian:13

RUN apt update -y && apt upgrade -y && apt install -y mariadb-server mariadb-client gettext-base

COPY ./50-server.cnf /etc/mysql/mariadb.conf.d/
COPY ./init.sql.template .
COPY ./entrypoint.sh .
RUN chmod +x ./entrypoint.sh
RUN chown -R mysql:mysql /run/mysqld

EXPOSE 3306

LABEL version="11.8"
LABEL description="MariaDB_Server"

ENTRYPOINT [ "./entrypoint.sh" ]
CMD [ "mysqld" ]
