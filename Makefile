.PHONY: all build up down clean fclean re

DATA_DIR = /home/rmamisoa/data

all: create_dirs build up

create_dirs:
	mkdir -p $(DATA_DIR)/mariadb
	mkdir -p $(DATA_DIR)/wordpress

build:
	docker compose --env-file .env -f srcs/docker-compose.yml build

up: create_dirs
	docker compose --env-file .env -f srcs/docker-compose.yml up -d

down:
	docker compose --env-file .env -f srcs/docker-compose.yml down

stop:
	docker compose --env-file .env -f srcs/docker-compose.yml stop

start:
	docker compose --env-file .env -f srcs/docker-compose.yml start

restart: down up

clean: down
	docker compose --env-file .env -f srcs/docker-compose.yml rm -f

fclean: clean
	docker run --rm -v $(DATA_DIR):/data alpine sh -c "rm -rf /data/mariadb/* /data/wordpress/*" 2>/dev/null || true
	docker volume rm $$(docker volume ls -q) 2>/dev/null || true
	docker system prune -a -f

#fclean: clean
#	@docker system prune -af --volumes
#	@docker volume prune -f
#	@docker run --rm -v $(DATA_DIR)/mariadb:/data debian:bookworm sh -c 'rm -rf /data/*' >/dev/null 2>&1 || true
#	@docker run --rm -v $(DATA_DIR)/wordpress:/data debian:bookworm sh -c 'rm -rf /data/*' >/dev/null 2>&1 || true
#	@rmdir $(DATA_DIR)/mariadb $(DATA_DIR)/wordpress 2>/dev/null || true

re: fclean all