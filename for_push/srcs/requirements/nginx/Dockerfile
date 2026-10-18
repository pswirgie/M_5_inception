FROM debian:13

RUN apt update -y && apt upgrade -y && apt install -y nginx openssl && apt install curl -y 

RUN mkdir -p /etc/nginx/ssl
RUN openssl req -x509 -nodes -out /etc/nginx/ssl/certificate.crt -keyout /etc/nginx/ssl/certificate.key -subj ""


COPY ./50-server.cnf /etc/mysql/mariadb.conf.d/

EXPOSE 443

