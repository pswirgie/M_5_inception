*This project has been created as part of the 42 curriculum by pswirgie.*

# Inception

## Description

Inception is a system administration project whose goal is to build a small web infrastructure with **Docker** and **Docker Compose**, inside a virtual machine. Every service runs in its own container, built from our own Dockerfiles (no ready-made images are pulled, except the Debian base image).

The stack is made of three services:

| Service     | Role                                              | Exposed                         |
|-------------|---------------------------------------------------|---------------------------------|
| `nginx`     | Reverse proxy / web server, TLS 1.2 and 1.3 only  | Port **443** (only entry point) |
| `wordpress` | WordPress + PHP-FPM (no web server inside)        | Port 9000, internal network only |
| `mariadb`   | MariaDB database for WordPress                    | Port 3306, internal network only |

```
                 https (443)
   Browser  ─────────────────►  nginx ──── fastcgi (9000) ───►  wordpress ──── sql (3306) ───►  mariadb
                                  │                                │                               │
                                  └──────── volume: wordpress ─────┘                         volume: mariadb
                                       (/home/pswirgie/data/wordpress)                (/home/pswirgie/data/mariadb)
```

### Sources included in the project

```
.
├── Makefile                      # entry point: builds and manages the stack
├── secrets/                      # passwords (Docker secrets, NOT committed)
├── srcs/
│   ├── docker-compose.yml        # services, network, volumes, secrets
│   ├── .env                      # non-confidential variables (NOT committed)
│   ├── .env_template             # template of the .env file
│   └── requirements/
│       ├── nginx/                # Dockerfile + nginx.conf
│       ├── wordpress/            # Dockerfile + php-fpm pool config + install script (WP-CLI)
│       └── mariadb/              # Dockerfile + entrypoint + init.sql.template + server config
├── README.md
├── USER_DOC.md                   # user / administrator documentation
└── DEV_DOC.md                    # developer documentation
```

### Main design choices

- **Base image**: `debian:bookworm`, the penultimate stable Debian release. The `latest` tag is never used.
- **One service = one Dockerfile = one container.** Each image has the same name as its service (`nginx`, `wordpress`, `mariadb`).
- **PID 1 and foreground processes**: each container runs its daemon in the foreground (`nginx -g "daemon off;"`, `php-fpm8.2 -F`, `mysqld`), launched with `exec` from the entrypoint scripts. There is no `tail -f`, `sleep infinity` or infinite loop.
- **NGINX**: only entry point of the infrastructure, listens on port 443 only, accepts TLSv1.2 and TLSv1.3 only. A self-signed certificate is generated at image build time for `pswirgie.42.fr`.
- **WordPress**: downloaded, configured and installed on the first start with **WP-CLI** (`script.sh`). The script waits for MariaDB to be reachable, then creates the administrator and a second user (role `author`). The administrator username does not contain `admin`/`administrator`.
- **MariaDB**: the database, the application user and the root password are set through an `init_file` generated at start-up from `init.sql.template` (variables substituted with `envsubst`).
- **Credentials**: passwords are stored as **Docker secrets** (files in `secrets/`, mounted in `/run/secrets/` inside containers). Non-confidential values (domain name, user names, database name, e-mails) are in `srcs/.env`. No password is written in a Dockerfile or committed to Git.
- **Persistence**: two Docker **named volumes** (`mariadb` and `wordpress`) store their data on the host in `/home/pswirgie/data`.
- **Resilience**: containers use a restart policy (`restart: on-failure`) so they come back after a crash.
- **Network**: a dedicated bridge network named `inception` connects the containers. Containers reach each other by service name (`wordpress:9000`, `mariadb:3306`). `network: host` and `links` are not used.

### Virtual Machines vs Docker

| | Virtual Machine | Docker container |
|---|---|---|
| Isolation | Full virtualised hardware, with its own kernel | Isolated processes (namespaces, cgroups) sharing the host kernel |
| Size | Full OS per VM (gigabytes) | Only the application and its dependencies (megabytes) |
| Start-up | Tens of seconds to minutes | Seconds |
| Resource usage | Heavy (RAM and CPU reserved per VM) | Light, resources are shared |
| Portability | Heavier images, tied to a hypervisor | An image runs the same everywhere Docker runs |
| Security boundary | Stronger (separate kernel) | Weaker (shared kernel) |

Docker is a better fit here because the three services are small, need to start quickly, and must be reproducible from a few text files (Dockerfiles + Compose). A VM per service would be much heavier for the same result. The whole project still runs inside one VM, as required.

### Secrets vs Environment Variables

- **Environment variables** (`.env`, `env_file`) are simple, need no library, and are great for non-sensitive configuration (domain name, database name, user names). But they can leak: they appear in `docker inspect`, in the process environment, in logs or crash dumps, and are inherited by child processes.
- **Docker secrets** are files mounted read-only in `/run/secrets/<name>` inside the containers that were explicitly granted access. The value is not stored in the image, not shown in `docker inspect`, and not exported to the environment. The application reads it from the file at start-up.

In this project, passwords (database user, database root, WordPress administrator, WordPress user) are **secrets**; everything else is in the `.env` file. Both `secrets/` and `.env` are excluded from Git through `.gitignore`.

### Docker Network vs Host Network

- **Docker network (bridge)**: containers get their own virtual network, their own IP addresses, and can resolve each other by service name. Only the ports explicitly published (`443:443`) are reachable from outside. MariaDB and PHP-FPM are therefore not exposed to the host or the internet.
- **Host network** (`network: host`): the container shares the host's network stack. There is no isolation and no port mapping, and port conflicts with the host become possible. It is forbidden by the subject.

A custom bridge network (`inception`) gives isolation plus easy service discovery, which is exactly what the three services need.

### Docker Volumes vs Bind Mounts

- **Bind mount**: maps an existing host path directly into the container. It depends on the host's directory layout and permissions, and is managed outside Docker.
- **Docker (named) volume**: created and managed by Docker (`docker volume ls/inspect/rm`), independent of the container lifecycle, portable, and easier to back up or migrate.

The subject requires named volumes whose data lives in `/home/pswirgie/data`. They are therefore declared as named volumes (`mariadb`, `wordpress`) using the `local` driver with `driver_opts` (`type: none`, `o: bind`, `device: /home/pswirgie/data/...`). This keeps them real Docker volumes (visible with `docker volume ls`) while storing the data at the required location on the host.

## Instructions

### Prerequisites

- A Linux virtual machine with **Docker**, **Docker Compose** (v2, `docker compose`) and **make** installed.
- `sudo` rights (used by `make clean` to remove the data folders).

### 1. Configure the domain name

Point the domain to the local machine by adding this line to `/etc/hosts`:

```
127.0.0.1   pswirgie.42.fr
```

### 2. Create the configuration files

Create the environment file from the template and fill it in:

```bash
cp srcs/.env_template srcs/.env
```

| Variable      | Description                                                    |
|---------------|----------------------------------------------------------------|
| `DOMAIN_NAME` | Domain name of the website (`pswirgie.42.fr`)                  |
| `DB_USER`     | MariaDB user used by WordPress                                 |
| `DB_NAME`     | WordPress database name                                        |
| `ADMIN_USER`  | WordPress administrator username (must not contain "admin")    |
| `ADMIN_MAIL`  | WordPress administrator e-mail                                 |
| `WP_USER2`    | Username of the second WordPress user                          |
| `WP_MAIL2`    | E-mail of the second WordPress user                            |

Create the secrets (one password per file, in the `secrets/` folder at the root of the repository):

```bash
mkdir -p secrets
echo "your_db_password"        > secrets/db_password.txt
echo "your_db_root_password"   > secrets/db_root_password.txt
echo "your_wp_admin_password"  > secrets/wp_admin_password.txt
echo "your_wp_user_password"   > secrets/wp_user_password.txt
```

> Neither `srcs/.env` nor `secrets/` must ever be committed.

### 3. Build and run

```bash
make
```

This creates the data folders in `/home/pswirgie/data/`, builds the three images and starts the containers in the background.

### 4. Use the website

- Website: <https://pswirgie.42.fr>
- Administration panel: <https://pswirgie.42.fr/wp-admin>

The browser will warn about the certificate because it is self-signed; accept the exception to continue.

### Makefile commands

| Command               | Effect                                                                    |
|-----------------------|---------------------------------------------------------------------------|
| `make`                | Create data folders, build the images and start the stack                 |
| `make up`             | Start the containers (without rebuilding)                                 |
| `make down`           | Stop and remove the containers                                            |
| `make restart`        | `down` then `up`                                                          |
| `make logs`           | Show the logs of all services                                             |
| `make logs-nginx` / `logs-wordpress` / `logs-mariadb` | Show the logs of one service  |
| `make clean`          | Stop the stack, remove the volumes and **delete the data folders**        |
| `make fclean`         | `clean` + `docker system prune -af --volumes` (removes **all** Docker data of the machine) |
| `make re`             | `fclean` then `all`                                                       |
| `make reclean`        | `clean` then `all`                                                        |

### Useful checks

```bash
docker ps                      # the 3 containers must be "Up"
docker network ls              # network "inception"
docker volume ls               # volumes "mariadb" and "wordpress"
docker volume inspect wordpress
openssl s_client -connect pswirgie.42.fr:443 -tls1_2   # must succeed
openssl s_client -connect pswirgie.42.fr:443 -tls1_1   # must fail
```

More details are available in [USER_DOC.md](USER_DOC.md) (end user / administrator) and [DEV_DOC.md](DEV_DOC.md) (developer).

## Resources

### Documentation and tutorials

- [Introduction to Docker](https://www.geeksforgeeks.org/devops/introduction-to-docker/)
- [What is a Docker image](https://www.geeksforgeeks.org/devops/what-is-docker-image/)
- [NGINX: configuring HTTPS servers](https://nginx.org/en/docs/http/configuring_https_servers.html)
- [Installing an SSL certificate on NGINX](https://www.ssldragon.com/fr/how-to/install-ssl-certificate/nginx)
- [Debian distributions and ISO images](https://www.debian.org/distrib/)
- [Installing WP-CLI](https://make.wordpress.org/cli/handbook/guides/installing/)
- [WP-CLI `wp core` commands](https://developer.wordpress.org/cli/commands/core/)
- [WP-CLI command reference](https://developer.wordpress.org/cli/commands/)
- [Docker Compose documentation](https://docs.docker.com/compose/)
- [Docker Compose: using secrets](https://docs.docker.com/compose/how-tos/use-secrets/)
- [Docker volumes](https://docs.docker.com/engine/storage/volumes/)
- [Docker networking](https://docs.docker.com/engine/network/)
- [WordPress with Docker (Hostinger tutorial)](https://www.hostinger.com/fr/tutoriels/docker-wordpress/)
- The Dockerfiles (MariaDB, NGINX) and the `docker-compose` file of my previous 42 project **Matcha** were used as a starting point.

### Use of AI

AI tools were used as a learning aid: to understand the concepts involved (Docker, Compose, PID 1, TLS, secrets, volumes), to learn how to search for and find the right information in the documentation and redaction of documentations. The configuration files, Dockerfiles and scripts were written, tested and are understood by me.
