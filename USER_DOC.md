# User Documentation

This document explains, in simple terms, how to use the Inception stack as an end user or administrator: what it provides, how to start and stop it, how to reach the website, where the credentials are, and how to check that everything works.

For installation and technical details, see [DEV_DOC.md](DEV_DOC.md).

## 1. What this stack provides

The stack runs a WordPress website, protected by HTTPS, made of three services. Each one runs in its own Docker container.

| Service     | What it does                                                          | Reachable from outside? |
|-------------|-----------------------------------------------------------------------|-------------------------|
| `nginx`     | Web server: receives the visitors' requests over **HTTPS (port 443)** | Yes, the only entry point |
| `wordpress` | The WordPress website itself (PHP-FPM)                                | No, internal only       |
| `mariadb`   | The database storing the pages, posts, comments and user accounts     | No, internal only       |

Your website content and database are saved on the machine in `/home/pswirgie/data`, so they are kept when the stack is stopped or restarted.

## 2. Start and stop the project

All commands are run from the **root of the repository** (the folder containing the `Makefile`).

| I want to...                                  | Command         |
|-----------------------------------------------|-----------------|
| Start the project (first time, or after a change) | `make`      |
| Start it again after a stop                   | `make up`       |
| Stop it (data is kept)                        | `make down`     |
| Restart it                                    | `make restart`  |

> **Warning**: `make clean`, `make fclean` and `make re` **delete all the website data and the database**. Only use them if you want to start again from zero.

The first start takes a few minutes because the images are built and WordPress is installed. Later starts take a few seconds.

## 3. Access the website and the administration panel

### Before the first visit

The domain name must point to the machine. Check that this line is in `/etc/hosts`:

```
127.0.0.1   pswirgie.42.fr
```

### Addresses

| What                    | Address                              |
|-------------------------|--------------------------------------|
| Website                 | <https://pswirgie.42.fr>             |
| Administration panel    | <https://pswirgie.42.fr/wp-admin>    |

The connection is only available in **HTTPS**. The browser shows a security warning because the certificate is **self-signed** (created by the project, not by a public authority). This is expected: choose "Advanced", then "Continue to pswirgie.42.fr".

### Accounts

WordPress has two accounts:

| Account         | Role           | What it can do                                         |
|-----------------|----------------|--------------------------------------------------------|
| Administrator   | Administrator  | Manage the whole site: pages, themes, plugins, users, settings |
| Second user     | Author         | Write and publish their own posts                      |

To log in, open <https://pswirgie.42.fr/wp-admin>, enter the username and the password (see the next section), then click "Log In".

## 4. Locate and manage the credentials

Credentials are split in two places, both **outside Git** and never to be shared or committed.

### Usernames, e-mails and database name: `srcs/.env`

```bash
cat srcs/.env
```

| Variable      | Meaning                                         |
|---------------|-------------------------------------------------|
| `ADMIN_USER`  | Username of the WordPress administrator         |
| `ADMIN_MAIL`  | E-mail of the WordPress administrator           |
| `WP_USER2`    | Username of the second WordPress user           |
| `WP_MAIL2`    | E-mail of the second WordPress user             |
| `DB_USER`     | Database user used by WordPress                 |
| `DB_NAME`     | Database name                                   |
| `DOMAIN_NAME` | Domain name of the website                      |

### Passwords: the `secrets/` folder

Each password is stored in its own file:

| File                              | Password of                         |
|-----------------------------------|-------------------------------------|
| `secrets/wp_admin_password.txt`   | WordPress administrator             |
| `secrets/wp_user_password.txt`    | WordPress second user               |
| `secrets/db_password.txt`         | Database user (`DB_USER`)           |
| `secrets/db_root_password.txt`    | Database root account               |

To read one:

```bash
cat secrets/wp_admin_password.txt
```

### Changing a password

- **A WordPress account password** (administrator or second user): log in to the administration panel, go to **Users → Profile**, and set a new password. This is the simplest way and takes effect immediately. The file in `secrets/` is only used at the **first installation**, so it is not updated by this change: keep your own record of the new password.
- **Any value in `.env` or `secrets/`, applied from scratch**: the new values are only used when the data is created for the first time. To apply them, edit the files and run `make reclean`. **This erases the website and the database.**

## 5. Check that the services are running

### Quick check

```bash
docker ps
```

Three containers must be listed with a status beginning with **"Up"**: `nginx`, `wordpress` and `mariadb`. Port `443` must appear for `nginx`.

You can also use:

```bash
docker compose -f srcs/docker-compose.yml ps
```

### Check the website

1. Open <https://pswirgie.42.fr>: the WordPress site must be displayed (after accepting the certificate warning).
2. Open <https://pswirgie.42.fr/wp-admin> and log in with the administrator account.

### Check the logs

```bash
make logs              # all services
make logs-nginx        # web server
make logs-wordpress    # WordPress / PHP
make logs-mariadb      # database
```

### Check that the data is kept

```bash
docker volume ls
```

The volumes `mariadb` and `wordpress` must be listed. Their content is in `/home/pswirgie/data/`.

## 6. If something goes wrong

| Problem                                          | What to do                                                            |
|--------------------------------------------------|-----------------------------------------------------------------------|
| The page does not load                           | Check `docker ps`, then the `/etc/hosts` line                         |
| "Your connection is not private" warning         | Normal (self-signed certificate): continue to the site                |
| One container is missing or stopped              | Run `make up`, then `make logs` to see the error                      |
| The site does not load right after `make`        | Wait one or two minutes: WordPress and the database are still starting |
| I forgot a WordPress password                    | Use "Lost your password?" on the login page, or read `secrets/*.txt` (initial password only) |
| I want to start again from zero                  | `make re` (**erases all data**)                                       |
