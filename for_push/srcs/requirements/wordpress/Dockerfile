FROM debian:bookworm

//package wordpress
COPY ./tools/script.sh .
WORKDIR /usr/src/myapp
EXPOSE 9000
ENTRYPOINT [ "/var/www/html/script.sh" ]
// mettre dans entrypoint le system pour configurer cli
CMD [ "php", "./tools/script.sh" ]