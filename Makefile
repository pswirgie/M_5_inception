COMPOSE = docker compose -f srcs/docker-compose.yml

all:
	@mkdir -p /home/pswirgie/data/mariadb /home/pswirgie/data/wordpress
	@$(COMPOSE) up -d --build

up:
	@$(COMPOSE) up -d

down:
	@$(COMPOSE) down

restart: down up

logs:
	@$(COMPOSE) logs 

logs-mariadb:
	@$(COMPOSE) logs mariadb

logs-nginx:
	@$(COMPOSE) logs nginx

logs-wordpress:
	@$(COMPOSE) logs wordpress

clean:
	@$(COMPOSE) down -v --remove-orphans
	@sudo rm -rf /home/pswirgie/data/mariadb /home/pswirgie/data/wordpress

fclean: clean
	@docker system prune -af --volumes

re: fclean all

reclean: clean all

.PHONY: all up down restart logs logs-mariadb logs-nginx logs-wordpress clean fclean re reclean
