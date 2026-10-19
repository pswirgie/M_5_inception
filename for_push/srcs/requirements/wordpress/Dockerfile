FROM debian:bookworm

RUN apt-get update && apt-get install -y \
	curl mariadb-client \
	php8.2-fpm php8.2-mysql php8.2-curl php8.2-gd \
	php8.2-mbstring php8.2-xml php8.2-zip \
	&& rm -rf /var/lib/apt/lists/*

RUN curl -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
	&& chmod +x /usr/local/bin/wp

COPY ./tools/script.sh /usr/local/bin/script.sh
RUN chmod +x script.sh \
	&& mkdir -p /run/php /var/www/html
COPY ./conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf

WORKDIR /var/www/html

EXPOSE 9000

ENTRYPOINT [ "/usr/local/bin/script.sh" ]
CMD [ "php-fpm8.2", "-F" ]
