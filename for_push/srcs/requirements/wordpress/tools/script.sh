curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar

if [ ! -f wp-config.php ]; then
	wp config create --dbname=$DB_NAME --dbuser=$DB_USER --dbpass=$DB_PASSWORD --dbhost=mariadb --skip-check --allow-root


// php-fpm pas nginx
wordpress configure
une base de donnee avec mariadb
deux utilisateurs un admin et un autre
un volume pour les fichiers

