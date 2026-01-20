FROM debian:bookworm

RUN apt-get update && apt-get install -y \
    php-fpm \
    php-mysql \
    php-curl \
    php-gd \
    php-intl \
    php-mbstring \
    php-xml \
    curl \
    wget \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/www/html /run/php

COPY conf/php-fpm.conf /etc/php/8.2/fpm/pool.d/www.conf
COPY tools/wordpress.sh /wordpress.sh

RUN chmod +x /wordpress.sh

EXPOSE 9000

ENTRYPOINT ["/wordpress.sh"]
