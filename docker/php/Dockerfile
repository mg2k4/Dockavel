FROM php:8.4-fpm

ARG APP_ENV=local

ENV DOCKERIZE_VERSION 0.9.7
RUN curl -sSfL https://github.com/jwilder/dockerize/releases/download/v${DOCKERIZE_VERSION}/dockerize-linux-amd64-v${DOCKERIZE_VERSION}.tar.gz \
    | tar -C /usr/local/bin -xzv \
    && rm -rf /tmp/*

RUN curl -sS https://getcomposer.org/installer -o composer-setup.php \
    && php composer-setup.php --install-dir=/usr/local/bin --filename=composer --2 \
    && rm composer-setup.php

RUN set -uex; \
    apt-get update; \
    apt-get install -y ca-certificates curl gnupg; \
    mkdir -p /etc/apt/keyrings; \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
     | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg; \
    NODE_MAJOR=20; \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" \
     > /etc/apt/sources.list.d/nodesource.list; \
    apt-get -qy update; \
    apt-get -qy install nodejs;

RUN apt-get update && apt-get install -y --no-install-recommends \
        libz-dev \
        libjpeg-dev \
        libpng-dev \
        libssl-dev \
        libzip-dev \
        unzip \
        zip \
        supervisor \
        default-mysql-client \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && pecl install redis \
    && docker-php-ext-configure gd \
    && docker-php-ext-configure zip \
    && docker-php-ext-install \
        gd \
        exif \
        opcache \
        pdo_mysql \
        pcntl \
        zip \
        fileinfo \
    && docker-php-ext-enable redis

# Copy PHP config (same for dev and prod)
COPY ./docker/php/php.ini /usr/local/etc/php/conf.d/php.ini

# Copy OPcache configs
COPY ./docker/php/opcache.*.ini /tmp/

# Select OPcache config based on APP_ENV
RUN if [ "$APP_ENV" = "production" ]; then \
        mv /tmp/opcache.prod.ini /usr/local/etc/php/conf.d/opcache.ini; \
    else \
        mv /tmp/opcache.dev.ini /usr/local/etc/php/conf.d/opcache.ini; \
    fi \
    && rm -f /tmp/*.ini

WORKDIR /usr/src/app

RUN mkdir -p /var/log/supervisor \
    && mkdir -p /etc/supervisor/conf.d

COPY ./docker/supervisor/supervisord.conf /etc/supervisor/supervisord.conf

RUN mkdir -p /usr/src/app/storage /usr/src/app/bootstrap/cache \
    && chown -R www-data:www-data /usr/src/app/storage /usr/src/app/bootstrap/cache \
    && chmod -R 775 /usr/src/app/storage /usr/src/app/bootstrap/cache

RUN echo "alias pa='php artisan'" >> ~/.bashrc
