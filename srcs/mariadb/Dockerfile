FROM debian:trixie

ENV DEBIAN_FRONTEND=noninteractive

# Install MariaDB server
RUN apt-get update && \
    apt-get install -y mariadb-server mariadb-client && \
    rm -rf /var/lib/apt/lists/*

# Create necessary directories and set permissions
RUN mkdir -p /var/run/mysqld && \
    chown -R mysql:mysql /var/run/mysqld && \
    chmod 755 /var/run/mysqld

# Copy initialization script
COPY conf/init.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/init.sh

EXPOSE 3306

CMD ["mariadbd", "--bind-address=0.0.0.0"]