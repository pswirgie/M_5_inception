all:
	@mkdir -p /home/pswirgie/data/mariadb /home/pswirgie/data/wordpress
	@docker compose -f srcs/docker-compose.yml up -d --build

up:
	@docker compose -f srcs/docker-compose.yml up -d

down:
	@docker compose -f srcs/docker-compose.yml down

restart: down up

logs:
	docker compose logs

logs-mariadb:
	docker compose logs mariadb

logs-nginx:
	docker compose logs nginx

logs-wordpress:
	docker compose logs wordpress

clean:
	@docker compose -f srcs/docker-compose.yml down -v --remove-orphans
	@sudo rm -rf /home/pswirgie/data/mariadb /home/pswirgie/data/wordpress

fclean: clean
	@docker system prune -af --volumes

re: fclean all

reclean: clean all

.PHONY: all fclean clean re
