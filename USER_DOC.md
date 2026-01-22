# User Documentation

## Accessing the Website

### WordPress Site

Access your WordPress site at:
```
https://rmamisoa.42.fr
```

> **Note**: You may see a browser security warning because the SSL certificate is self-signed. Click "Advanced" and "Proceed" to continue.

### Admin Panel

Access the WordPress admin panel at:
```
https://rmamisoa.42.fr/wp-admin
```

**Default Admin Credentials:**
- Username: Check `WORDPRESS_ADMIN_USER` in `.env` file
- Password: Check `secrets/wordpress_admin_password.txt`

**Regular User Credentials:**
- Username: Check `WORDPRESS_USER` in `.env` file
- Password: Check `secrets/wordpress_user_password.txt`

---

## Managing Credentials

### Changing WordPress Admin Password

1. Log in to the admin panel at `/wp-admin`
2. Go to **Users** → **Profile**
3. Scroll down to **Account Management**
4. Click **Set New Password**
5. Save changes

### Changing Database Passwords

1. Stop the containers: `make down`
2. Edit the relevant file in `secrets/`:
   - `mysql_root_password.txt` - MariaDB root password
   - `mysql_admin_password.txt` - Database admin password
   - `mysql_password.txt` - WordPress database user password
3. Run `make fclean` to reset everything
4. Run `make` to rebuild with new credentials

> **Warning**: Changing database passwords requires a full rebuild and will reset your WordPress data.

---

## Basic Health Checks

### Check if Services are Running

```bash
docker ps
```

You should see 3 containers running:
- `nginx`
- `wordpress`
- `mariadb`

### Check Container Logs

```bash
# All logs
docker compose -f srcs/docker-compose.yml logs

# Specific service
docker compose -f srcs/docker-compose.yml logs nginx
docker compose -f srcs/docker-compose.yml logs wordpress
docker compose -f srcs/docker-compose.yml logs mariadb
```

### Restart Services

```bash
make restart
```

### Check HTTPS Certificate

```bash
curl -k -I https://rmamisoa.42.fr
```

Expected: `HTTP/2 200` or `HTTP/1.1 200 OK`

---

## Troubleshooting

### Cannot Access Website

1. Check if containers are running: `docker ps`
2. Check nginx logs: `docker logs nginx`
3. Verify port 443 is not blocked by firewall

### WordPress Installation Page Appears

If you see the WordPress installation wizard instead of your site:
1. Check wordpress logs: `docker logs wordpress`
2. The automatic installation may have failed
3. Run `make fclean && make` to reset and reinstall

### Database Connection Error

1. Check if mariadb is running: `docker ps | grep mariadb`
2. Check mariadb logs: `docker logs mariadb`
3. Verify credentials in `.env` and `secrets/` match

### Reset Everything

To completely reset the installation:
```bash
make fclean
make
```

> **Warning**: This will delete all WordPress content and database data.
