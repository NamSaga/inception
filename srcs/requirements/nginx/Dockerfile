FROM debian:bookworm

RUN apt-get update && apt-get install -y \
    nginx \
    openssl \
    && rm -rf /var/lib/apt/lists/*

COPY conf/nginx.conf /etc/nginx/sites-available/default
COPY tools/nginx.sh /nginx.sh


RUN chmod +x /nginx.sh

ARG NGINX_PORT=443
EXPOSE ${NGINX_PORT}

ENTRYPOINT ["/nginx.sh"]
