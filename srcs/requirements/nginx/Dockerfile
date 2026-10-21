FROM debian:bookworm

RUN apt update -y && apt upgrade -y && apt install -y nginx openssl && apt install curl -y 

RUN mkdir -p /etc/nginx/ssl
RUN mkdir -p /etc/nginx/ssl \
    && openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/certificate.key \
        -out /etc/nginx/ssl/certificate.crt \
        -subj "/C=FR/ST=IDF/L=Paris/O=42/OU=42/CN=${DOMAIN_NAME}"

COPY ./conf/nginx.conf /etc/nginx/nginx.conf

EXPOSE 443

RUN chmod 755 /var/www/html
RUN chown -R www-data:www-data /var/www/html

CMD ["nginx", "-g", "daemon off;"]
