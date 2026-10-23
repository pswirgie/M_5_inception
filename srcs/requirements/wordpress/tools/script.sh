#!/bin/sh

chmod +x /usr/local/bin/wp

DB_PASSWORD=$(cat /run/secrets/db_password)
ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
WP_PASS2=$(cat /run/secrets/wp_user_password)

until mysqladmin ping -h mariadb -u"$DB_USER" -p"$DB_PASSWORD" --silent; do
	echo "En attente de MariaDB..."
	sleep 2
done

if [ ! -f wp-config.php ]; then
	wp core download --allow-root
	wp config create \
		--allow-root \
		--dbname="$DB_NAME" --dbuser="$DB_USER" \
		--dbpass="$DB_PASSWORD" --dbhost=mariadb \
		--skip-check
	wp core install \
		--allow-root --url=https://"$DOMAIN_NAME" \
		--title=inception --admin_user="$ADMIN_USER" \
		--admin_password="$ADMIN_PASSWORD" --admin_email="$ADMIN_MAIL" \
		--skip-email
	chown -R www-data:www-data /var/www/html
	wp user create "$WP_USER2" "$WP_MAIL2" \
		--role=author \
		--user_pass="$WP_PASS2" \
		--allow-root
fi

exec "$@"
