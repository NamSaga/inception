.PHONY: all build up down clean fclean re

DATA_DIR = /home/saga37/data

all: create_dirs build up

create_dirs:
	mkdir -p $(DATA_DIR)/mariadb
	mkdir -p $(DATA_DIR)/wordpress

build:
	docker-compose -f srcs/docker-compose.yml build

up: create_dirs
	docker-compose -f srcs/docker-compose.yml up -d

down:
	docker-compose -f srcs/docker-compose.yml down

stop:
	docker-compose -f srcs/docker-compose.yml stop

start:
	docker-compose -f srcs/docker-compose.yml start

restart: down up

logs:
	docker-compose -f srcs/docker-compose.yml logs -f

ps:
	docker-compose -f srcs/docker-compose.yml ps

clean: down
	docker-compose -f srcs/docker-compose.yml rm -f

fclean: clean
	docker volume rm $$(docker volume ls -q) 2>/dev/null || true
	docker image rm mariadb:latest wordpress:latest nginx:latest 2>/dev/null || true
	rm -rf $(DATA_DIR)

re: fclean all

help:
	@echo "Available commands:"
	@echo "  make all       - Create data dirs, build and start containers"
	@echo "  make build     - Build Docker images"
	@echo "  make up        - Start containers"
	@echo "  make down      - Stop and remove containers"
	@echo "  make stop      - Stop containers"
	@echo "  make start     - Start containers"
	@echo "  make restart   - Restart containers"
	@echo "  make logs      - View container logs"
	@echo "  make ps        - Show container status"
	@echo "  make clean     - Remove containers"
	@echo "  make fclean    - Full clean (remove containers, images, volumes, data)"
	@echo "  make re        - Full rebuild"
