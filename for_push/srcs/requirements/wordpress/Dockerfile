FROM debian:bookworm

RUN apt update -y && apt upgrade -y && apt install -y curl php-fpm php-mysqli

RUN curl -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
	&& chmod +x wp-cli.phar \
	&& mv wp-cli.phar /usr/local/bin/wp


COPY ./tools/script.sh .
RUN chmod +x script.sh
COPY ./conf/www.conf .

WORKDIR /usr/src/wordpress

EXPOSE 9000

ENTRYPOINT [ "/var/www/html/script.sh" ]
CMD [ "php-fpm8.2", "-F" ]