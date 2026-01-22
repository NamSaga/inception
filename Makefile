.PHONY: all build up down clean fclean re

DATA_DIR = /home/rmamisoa/data
SRC_DIR = $(shell pwd)/srcs

all: create_dirs build up

create_dirs:
	mkdir -p $(DATA_DIR)/mariadb
	mkdir -p $(DATA_DIR)/wordpress

prepare_env:
	cp $(SRC_DIR)/.env .env

build: prepare_env
	docker compose --env-file .env -f $(SRC_DIR)/docker-compose.yml build

up: create_dirs prepare_env
	docker compose --env-file .env -f $(SRC_DIR)/docker-compose.yml up -d

down:
	docker compose --env-file .env -f $(SRC_DIR)/docker-compose.yml down

stop:
	docker compose --env-file .env -f $(SRC_DIR)/docker-compose.yml stop

start:
	docker compose --env-file .env -f $(SRC_DIR)/docker-compose.yml start

restart: down up

clean: down
	docker compose --env-file .env -f $(SRC_DIR)/docker-compose.yml rm -f

fclean: clean
	rm -f .env
	docker run --rm -v $(DATA_DIR):/data alpine sh -c "rm -rf /data/mariadb/* /data/wordpress/*" 2>/dev/null || true
	docker volume rm $$(docker volume ls -q) 2>/dev/null || true
	docker system prune -a -f

re: fclean all