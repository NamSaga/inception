# Developer Documentation

## Prerequisites

- **Docker** (version 20.10+)
- **Docker Compose** (version 2.0+ or docker-compose v1.29+)
- **Make**
- **Git**

### Verify Installation

```bash
docker --version
docker compose version
make --version
```

---

## Project Structure

```
inception/
├── .env                     # Environment variables
├── Makefile                 # Build automation
├── README.md                # Project overview
├── USER_DOC.md              # End-user documentation
├── DEV_DOC.md               # This file
├── secrets/                 # Docker secrets (passwords)
│   ├── mysql_root_password.txt
│   ├── mysql_admin_password.txt
│   ├── mysql_password.txt
│   ├── wordpress_admin_password.txt
│   └── wordpress_user_password.txt
└── srcs/
    ├── docker-compose.yml   # Service definitions
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   ├── conf/my.cnf
        │   └── tools/init.sh
        ├── nginx/
        │   ├── Dockerfile
        │   ├── conf/nginx.conf
        │   └── tools/nginx.sh
        └── wordpress/
            ├── Dockerfile
            ├── conf/php-fpm.conf
            └── tools/wordpress.sh
```

---

## Initial Setup

### 1. Clone the Repository

```bash
git clone <repository-url>
cd inception
```

### 2. Configure Environment Variables

Edit `.env` at the project root:

```bash
# Database config
MYSQL_DATABASE=wordpress_db
MYSQL_ADMIN_USER=rmamisoa
MYSQL_USER=user

# WordPress config
WORDPRESS_ADMIN_USER=rmamisoa
WORDPRESS_ADMIN_EMAIL=admin@rmamisoa.42.fr
WORDPRESS_USER=regular_user
WORDPRESS_USER_EMAIL=user@rmamisoa.42.fr
WORDPRESS_URL=rmamisoa.42.fr
```

### 3. Configure Secrets

Create password files in `secrets/`:

```bash
echo "your_root_password" > secrets/mysql_root_password.txt
echo "your_admin_password" > secrets/mysql_admin_password.txt
echo "your_db_password" > secrets/mysql_password.txt
echo "your_wp_admin_password" > secrets/wordpress_admin_password.txt
echo "your_wp_user_password" > secrets/wordpress_user_password.txt
```

### 4. Add Host Entry (Development)

```bash
sudo echo "127.0.0.1 rmamisoa.42.fr" >> /etc/hosts
```

---

## Makefile Commands

| Command | Description |
|---------|-------------|
| `make` | Create directories, build images, and start containers |
| `make all` | Same as `make` |
| `make create_dirs` | Create data directories for volumes |
| `make build` | Build Docker images only |
| `make up` | Start containers (creates dirs first) |
| `make down` | Stop and remove containers |
| `make stop` | Stop containers without removing |
| `make start` | Start previously stopped containers |
| `make restart` | Stop and start containers |
| `make clean` | Stop containers and remove them |
| `make fclean` | Full cleanup: containers, volumes, data, images |
| `make re` | Full rebuild (`fclean` + `all`) |

---

## Docker Compose Commands

The compose file is located at `srcs/docker-compose.yml`. All commands should include the env file:

```bash
# Build images
docker compose --env-file .env -f srcs/docker-compose.yml build

# Start services
docker compose --env-file .env -f srcs/docker-compose.yml up -d

# Stop services
docker compose --env-file .env -f srcs/docker-compose.yml down

# View logs
docker compose --env-file .env -f srcs/docker-compose.yml logs -f

# Execute command in container
docker compose --env-file .env -f srcs/docker-compose.yml exec wordpress bash

# Rebuild single service
docker compose --env-file .env -f srcs/docker-compose.yml build wordpress
docker compose --env-file .env -f srcs/docker-compose.yml up -d wordpress
```

---

## Data Persistence

### Volumes

Data is persisted using bind mounts to the host filesystem:

| Volume | Host Path | Container Path | Service |
|--------|-----------|----------------|---------|
| `mariadb_data` | `/home/rmamisoa/data/mariadb` | `/var/lib/mysql` | mariadb |
| `wordpress_data` | `/home/rmamisoa/data/wordpress` | `/var/www/html` | wordpress, nginx |

### Backup Data

```bash
# Backup WordPress files
sudo tar -czvf wordpress_backup.tar.gz /home/rmamisoa/data/wordpress

# Backup MariaDB data
sudo tar -czvf mariadb_backup.tar.gz /home/rmamisoa/data/mariadb

# Or use mysqldump inside container
docker exec mariadb mysqldump -u root -p<password> wordpress_db > backup.sql
```

### Restore Data

```bash
# Stop containers
make down

# Restore files
sudo tar -xzvf wordpress_backup.tar.gz -C /
sudo tar -xzvf mariadb_backup.tar.gz -C /

# Start containers
make up
```

### Clear All Data

```bash
make fclean
```

This removes:
- All containers
- All volumes
- All data in `/home/rmamisoa/data/`
- All related Docker images

---

## Network Architecture

All services communicate through the `inception_network` bridge network:

```
┌────────────────────────────────────────────────────┐
│                inception_network                    │
│                                                     │
│  ┌─────────┐    ┌─────────────┐    ┌─────────────┐ │
│  │  nginx  │───▶│  wordpress  │───▶│   mariadb   │ │
│  │  :8443   │    │    :9000    │    │    :3306    │ │
│  └─────────┘    └─────────────┘    └─────────────┘ │
│       │                                             │
└───────┼─────────────────────────────────────────────┘
        │
        ▼
   Host :8443

```

- **nginx** → Exposed on host port 8443, reverse proxies to wordpress:9000
- **wordpress** → PHP-FPM listening on port 9000 (internal only)
- **mariadb** → MySQL on port 3306 (internal only)

---

## Secrets Management

Docker secrets are used to securely pass sensitive data to containers:

```yaml
secrets:
  mysql_root_password:
    file: ../secrets/mysql_root_password.txt
```

Inside containers, secrets are available at `/run/secrets/<secret_name>`.

Scripts read them like this:
```bash
if [ -f /run/secrets/mysql_password ]; then
    MYSQL_PASSWORD=$(cat /run/secrets/mysql_password)
fi
```

---

## Debugging

### Access Container Shell

```bash
docker exec -it nginx bash
docker exec -it wordpress bash
docker exec -it mariadb bash
```

### Check WordPress Installation

```bash
docker exec wordpress wp core is-installed --allow-root
```

### Test Database Connection

```bash
docker exec mariadb mariadb -u user -p<password> -e "SHOW DATABASES;"
```

### View Real-time Logs

```bash
docker logs -f wordpress
docker logs -f mariadb
docker logs -f nginx
```

### Inspect Container

```bash
docker inspect wordpress
docker inspect mariadb
docker inspect nginx
```
