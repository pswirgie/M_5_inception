FROM debian:bookworm

RUN apt update -y && apt upgrade -y && apt install -y curl php-fpm php-mysqli

COPY ./tools/script.sh .

WORKDIR /usr/src/myapp

EXPOSE 9000

ENTRYPOINT [ "/var/www/html/script.sh" ]
// mettre dans entrypoint le system pour configurer cli
CMD [ "php", "./tools/script.sh" ]