FROM nginx:latest

RUN apt-get update && \
    apt-get install -y curl && \
    rm -rf /var/lib/apt/lists/*

ENV NGINX_ROOT=/usr/src/app/public
ENV NGINX_FPM_HOST=localhost
ENV NGINX_FPM_PORT=9000

RUN rm -f /etc/nginx/conf.d/default.conf

COPY ./docker/nginx/nginx.conf /etc/nginx/nginx.conf
COPY ./docker/nginx/fpm-http.conf /etc/nginx/fpm-http.conf
COPY ./docker/nginx/fpm-ssl.conf /etc/nginx/fpm-ssl.conf
COPY ./docker/nginx/entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 80 443

ENTRYPOINT ["entrypoint.sh"]
