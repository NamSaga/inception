FROM debian:bullseye

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
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/www/html

COPY conf/php-fpm.conf /etc/php/7.4/fpm/php-fpm.conf
COPY tools/wordpress.sh /wordpress.sh

RUN chmod +x /wordpress.sh

EXPOSE 9000

ENTRYPOINT ["/wordpress.sh"]
