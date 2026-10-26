# Developer Documentation

This document explains how a developer can set up, build, run and maintain the Inception stack from scratch.

The infrastructure is split into three services, each running in its own Docker container: **nginx**, **wordpress** (WordPress + PHP-FPM) and **mariadb**.

## 1. Prerequisites

- A Linux virtual machine (Debian recommended).
- **Git**, **Make**, **Docker Engine** and the **Docker Compose v2 plugin** (the `docker compose` command, not the old `docker-compose` binary).
- A user with `sudo` rights (the `clean` rule uses `sudo` to delete the data folders).
- A terminal and a code editor to edit the configuration files.
- Access to `/etc/hosts` (or to your DNS settings) to point the domain name to the machine.

### Installation

```bash
sudo apt update && sudo apt install -y git make
```

Install Docker Engine and the Compose plugin by following the official guide for your distribution: <https://docs.docker.com/engine/install/debian/>. The Debian package `docker-compose` installs the old v1 and is **not** what the Makefile uses (`docker compose -f ...`).

Allow your user to run Docker without `sudo`, then log out and back in:

```bash
sudo usermod -aG docker $USER
```

### Domain name

The website is served on `pswirgie.42.fr`. Point it to the local machine in `/etc/hosts`:

```
127.0.0.1   pswirgie.42.fr
```

## 2. Project layout

```
.
├── Makefile
├── secrets/                       # Docker secrets (not committed)
│   ├── db_password.txt
│   ├── db_root_password.txt
│   ├── wp_admin_password.txt
│   └── wp_user_password.txt
└── srcs/
    ├── docker-compose.yml
    ├── .env                       # variables (not committed)
    ├── .env_template
    └── requirements/
        ├── nginx/
        │   ├── Dockerfile
        │   └── conf/nginx.conf
        ├── wordpress/
        │   ├── Dockerfile
        │   ├── conf/www.conf
        │   └── tools/script.sh
        └── mariadb/
            ├── Dockerfile
            ├── entrypoint.sh
            ├── init.sql.template
            └── 50-server.cnf
```

## 3. Configuration from scratch

### 3.1 Environment file

```bash
cp srcs/.env_template srcs/.env
```

Fill in `srcs/.env`:

| Variable      | Description                                                   |
|---------------|---------------------------------------------------------------|
| `DOMAIN_NAME` | Domain name (`pswirgie.42.fr`)                                |
| `DB_USER`     | MariaDB user used by WordPress                                |
| `DB_NAME`     | WordPress database name                                       |
| `ADMIN_USER`  | WordPress administrator username (must not contain "admin")   |
| `ADMIN_MAIL`  | WordPress administrator e-mail                                |
| `WP_USER2`    | Username of the second WordPress user (role `author`)         |
| `WP_MAIL2`    | E-mail of the second WordPress user                           |

These variables are non-confidential. They are injected into the `wordpress` and `mariadb` containers with `env_file`.

### 3.2 Secrets

Passwords are **Docker secrets**: each one is a text file in `secrets/`, declared at the top of `docker-compose.yml` and mounted read-only in `/run/secrets/<name>` in the containers that need it.

```bash
mkdir -p secrets
echo "your_db_password"       > secrets/db_password.txt
echo "your_db_root_password"  > secrets/db_root_password.txt
echo "your_wp_admin_password" > secrets/wp_admin_password.txt
echo "your_wp_user_password"  > secrets/wp_user_password.txt
```

| Secret              | Used by                | Purpose                              |
|---------------------|------------------------|--------------------------------------|
| `db_password`       | `mariadb`, `wordpress` | Password of `DB_USER`                |
| `db_root_password`  | `mariadb`              | MariaDB root password                |
| `wp_admin_password` | `wordpress`            | WordPress administrator password     |
| `wp_user_password`  | `wordpress`            | Password of the second WordPress user |

> `secrets/` and `srcs/.env` are listed in `.gitignore`. Never commit them, and never write a password in a Dockerfile.

## 4. Build and launch

Everything goes through the Makefile, which calls `docker compose -f srcs/docker-compose.yml`.

```bash
make            # create data folders, build images, start the stack in the background
```

Main rules:

| Command            | Effect                                                                     |
|--------------------|----------------------------------------------------------------------------|
| `make`             | `mkdir -p` of the data folders + `docker compose up -d --build`            |
| `make up`          | Start the containers without rebuilding                                    |
| `make down`        | Stop and remove the containers (volumes and data are kept)                 |
| `make restart`     | `down` then `up`                                                           |
| `make logs`        | Logs of all services (`logs-nginx`, `logs-wordpress`, `logs-mariadb` for one service) |
| `make clean`       | `down -v --remove-orphans` + deletion of the data folders (**data lost**)  |
| `make fclean`      | `clean` + `docker system prune -af --volumes` (**removes all Docker data of the machine**) |
| `make re`          | `fclean` then `all` (full rebuild from zero)                               |
| `make reclean`     | `clean` then `all` (reset the data, keep the Docker cache)                 |

Once started, the website is available at <https://pswirgie.42.fr> and the administration panel at <https://pswirgie.42.fr/wp-admin>.

## 5. How the services work

### nginx

- Built from `debian:bookworm` with `nginx` and `openssl`.
- A self-signed certificate is generated at **build time** in `/etc/nginx/ssl`.
- `nginx.conf` listens on **443 only**, enables `TLSv1.2` and `TLSv1.3` only, serves `/var/www/html` and forwards `.php` requests to `wordpress:9000` (FastCGI).
- Runs in the foreground with `nginx -g "daemon off;"` (PID 1).

### wordpress

- Built from `debian:bookworm` with PHP 8.2 FPM and **WP-CLI**.
- The entrypoint `script.sh`:
  1. reads the passwords from `/run/secrets/`;
  2. waits until MariaDB answers (`mysqladmin ping`);
  3. **only if `wp-config.php` does not exist**: downloads WordPress, creates `wp-config.php`, installs the site, then creates the second user;
  4. `exec`s the main command `php-fpm8.2 -F` so PHP-FPM becomes PID 1.
- PHP-FPM listens on `0.0.0.0:9000` (`conf/www.conf`) and is reachable only from the `inception` network.

### mariadb

- Built from `debian:bookworm` with `mariadb-server`, `mariadb-client` and `gettext-base` (for `envsubst`).
- The entrypoint `entrypoint.sh`:
  1. fixes the ownership of `/run/mysqld` and `/var/lib/mysql`;
  2. initialises the data directory with `mariadb-install-db` **only if it is empty**;
  3. reads the passwords from `/run/secrets/` and generates `/etc/mysql/init.sql` from `init.sql.template` with `envsubst` (creates the database, the user, and sets the root password);
  4. `exec`s `mysqld` (PID 1).
- `50-server.cnf` points `init_file` to the generated SQL file and makes MariaDB listen on `0.0.0.0:3306` (reachable only inside the Docker network).

### Network

A single bridge network named `inception` connects the three containers, which reach each other by service name. Only nginx publishes a port to the host (`443:443`).

## 6. Managing containers and volumes

### Containers

```bash
docker ps                                    # running containers
docker compose -f srcs/docker-compose.yml ps # state of the stack
docker logs nginx                            # logs of one container
docker exec -it nginx bash                   # shell inside a container
docker exec -it wordpress bash
docker exec -it mariadb bash
docker kill nginx                            # simulate a crash: it must restart
```

### Database

```bash
docker exec -it mariadb mariadb -u root -p   # enter the root password (secrets/db_root_password.txt)
```

```sql
SHOW DATABASES;
USE wordpress;
SHOW TABLES;
SELECT user_login FROM wp_users;             -- the two WordPress users
```

### WordPress (WP-CLI)

```bash
docker exec -it wordpress wp user list --allow-root --path=/var/www/html
```

### Network and volumes

```bash
docker network ls
docker network inspect inception
docker volume ls
docker volume inspect mariadb
docker volume inspect wordpress
```

### Checking TLS

```bash
openssl s_client -connect pswirgie.42.fr:443 -tls1_2   # must succeed
openssl s_client -connect pswirgie.42.fr:443 -tls1_1   # must fail
```

### Rebuilding after a change

| What you changed                             | What to do                                       |
|----------------------------------------------|--------------------------------------------------|
| A Dockerfile or a file copied in an image    | `make down && make` (rebuilds the images)        |
| `srcs/.env` or a secret                      | `make reclean` (variables are applied at the first initialisation only, see below) |
| Something broken, unknown state              | `make re`                                        |

## 7. Data storage and persistence

The project data lives on the host machine, in `/home/pswirgie/data`:

| Folder on the host                | Docker volume | Mounted in                           | Content                     |
|-----------------------------------|---------------|--------------------------------------|-----------------------------|
| `/home/pswirgie/data/mariadb`     | `mariadb`     | `mariadb:/var/lib/mysql`             | WordPress database          |
| `/home/pswirgie/data/wordpress`   | `wordpress`   | `wordpress:/var/www/html` and `nginx:/var/www/html` | WordPress website files |

Both are Docker **named volumes**, declared with the `local` driver and `driver_opts` (`type: none`, `o: bind`, `device: <host folder>`), so Docker manages them (`docker volume ls`) while the data is stored at the required location on the host.

### How persistence works

- The data survives `make down`, `make restart`, a reboot of the machine and a container crash, because it is stored in the volumes, not in the containers.
- The initialisation is **idempotent**:
  - MariaDB runs `mariadb-install-db` only if `/var/lib/mysql/mysql` does not exist;
  - WordPress is downloaded and installed only if `wp-config.php` does not exist.
- Consequently, changing `.env` or the secrets after the first start has **no effect** on existing data (the database user, the WordPress accounts and `wp-config.php` already exist). To apply new values, reset the data with `make clean` (or `make reclean`).
- `make clean` and `make fclean` **permanently delete** `/home/pswirgie/data/mariadb` and `/home/pswirgie/data/wordpress`.

## 8. Troubleshooting

| Symptom                                         | Things to check                                                                 |
|-------------------------------------------------|---------------------------------------------------------------------------------|
| `pswirgie.42.fr` does not resolve               | The line in `/etc/hosts`                                                        |
| Browser certificate warning                     | Expected: the certificate is self-signed                                        |
| `wordpress` container loops on "En attente de MariaDB..." | `make logs-mariadb`; check `DB_USER`, `DB_NAME` and `secrets/db_password.txt` |
| `secret not found` / compose error              | The four files exist in `secrets/` and the paths in `docker-compose.yml` are right |
| Permission denied on `/home/pswirgie/data`      | The folders exist and you ran `make` with the user that owns them               |
| Changes in `.env` are ignored                   | Existing data is kept: run `make reclean`                                       |
| Port 443 already in use                         | Stop the service using it (`sudo ss -tlnp \| grep 443`)                         |

## 9. Resources

- [WordPress with Docker (Hostinger tutorial)](https://www.hostinger.com/fr/tutoriels/docker-wordpress/)
- [Docker Compose documentation](https://docs.docker.com/compose/)
- [Docker Compose: using secrets](https://docs.docker.com/compose/how-tos/use-secrets/)
- [Docker volumes](https://docs.docker.com/engine/storage/volumes/)
- [WP-CLI handbook](https://make.wordpress.org/cli/handbook/)
