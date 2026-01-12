FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    nginx \
    openssl \
    && rm -rf /var/lib/apt/lists/*

COPY conf/nginx.conf /etc/nginx/sites-available/default
COPY tools/nginx.sh /nginx.sh

RUN chmod +x /nginx.sh

EXPOSE 443

ENTRYPOINT ["/nginx.sh"]
