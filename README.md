*This project has been created as part of the 42 curriculum by rmamisoa*
# Inception

## Description

Inception is a Docker-based infrastructure project that sets up a complete WordPress environment using containerized services. The project deploys three main services:

- **NGINX** - A web server configured with TLS (HTTPS only on port 8443)
- **WordPress** - A PHP-FPM based WordPress installation
- **MariaDB** - A MySQL-compatible database server

All services run in separate Docker containers, communicate through a dedicated Docker network, and use persistent volumes for data storage. The project follows security best practices by using Docker secrets for sensitive credentials.

### Architecture

```
                    ┌─────────────┐
                    │   NGINX     │
                    │  (port 8443) │
                    └──────┬──────┘
                           │
                    ┌──────▼──────┐
                    │  WordPress  │
                    │  (PHP-FPM)  │
                    └──────┬──────┘
                           │
                    ┌──────▼──────┐
                    │   MariaDB   │
                    │  (port 3306)│
                    └─────────────┘
```

## Instructions

### Prerequisites

- Docker and Docker Compose installed
- Make installed

### Setup

1. Clone the repository

2. Configure environment variables in `.env`:
   ```
   MYSQL_DATABASE=wordpress_db
   MYSQL_ADMIN_USER=your_admin
   MYSQL_USER=your_user
   WORDPRESS_ADMIN_USER=wp_admin
   WORDPRESS_ADMIN_EMAIL=admin@example.com
   WORDPRESS_USER=wp_user
   WORDPRESS_USER_EMAIL=user@example.com
   WORDPRESS_URL=your_domain.com
   ```

3. Set up secrets in the `secrets/` folder:
   - `mysql_root_password.txt`
   - `mysql_admin_password.txt`
   - `mysql_password.txt`
   - `wordpress_admin_password.txt`
   - `wordpress_user_password.txt`

4. Build and start the containers:
   ```bash
   make
   ```

### Available Commands

| Command | Description |
|---------|-------------|
| `make` | Build and start all containers |
| `make build` | Build Docker images |
| `make up` | Start containers |
| `make down` | Stop containers |
| `make stop` | Stop containers without removing |
| `make start` | Start stopped containers |
| `make restart` | Restart all containers |
| `make clean` | Stop and remove containers |
| `make fclean` | Full cleanup (containers, volumes, data) |
| `make re` | Full rebuild |

### Accessing WordPress

Once running, access WordPress at: `https://your_domain.com`

## AI Usage

This project was developed with assistance from **GitHub Copilot** (Claude Opus 4.5). AI was mainly used for:

- **Code Review & Debugging**: Identifying issues in Docker configurations, shell scripts, and compose files
- **Path Configuration**: Updating file paths when restructuring the project (moving `secrets/` and `.env` to root level)
- **Script Improvements**: Enhancing the WordPress installation script to properly detect if WordPress is already installed using `wp core is-installed` instead of just checking for file existence
- **Documentation**: Generating this README file

All AI-generated code was reviewed and validated before implementation.
