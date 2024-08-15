FROM    php:8.2-fpm-alpine

LABEL	maintainer="Rizal Fauzie Ridwan <rizal@fauzie.id>"

ENV     DOMAIN=localhost \
        HOME=/app \
        TZ=Asia/Jakarta \
        REAL_IP_FROM=10.0.0.0/16 \
        USERNAME=app \
        COMPOSER_VERSION=2.7.7

RUN     apk add --no-cache --update linux-headers supervisor bash nano wget curl git \
        nginx libpng libjpeg-turbo icu-libs memcached libmemcached imagemagick \
        libssh2 gettext freetype libintl libzip libmcrypt nodejs npm yarn

RUN     apk add --virtual .build-deps $PHPIZE_DEPS libxml2-dev libpng-dev libzip-dev libssh2-dev \
        libjpeg-turbo-dev libwebp-dev zlib-dev libmemcached-dev imagemagick-dev \
        ncurses-dev gettext-dev icu-dev libxpm-dev libmcrypt-dev freetype-dev make gcc g++ autoconf

RUN     export CFLAGS="$PHP_CFLAGS" CPPFLAGS="$PHP_CPPFLAGS" LDFLAGS="$PHP_LDFLAGS"; \
        docker-php-source extract; \
        pecl install imagick; \
        docker-php-ext-enable imagick; \
        pecl install memcached; \
        docker-php-ext-enable memcached; \
        pecl install ssh2-1.3.1; \
        docker-php-ext-enable ssh2; \
        echo no | pecl install redis; \
        docker-php-ext-enable redis; \
        docker-php-ext-configure gd --with-jpeg --with-freetype; \
        docker-php-ext-configure intl --enable-intl; \
        docker-php-ext-configure pcntl --enable-pcntl; \
        docker-php-ext-configure opcache --enable-opcache; \
        docker-php-ext-install -j$(nproc) \
        bcmath exif gd gettext intl pcntl mysqli opcache pcntl pdo_mysql sockets zip

COPY    /files /

RUN     chmod +x /entrypoint.sh; \
        rm -rf /var/www/html; \
        docker-php-source delete; \
        apk del .build-deps; \
        rm -rf /var/cache/apk/*; \
        rm -rf /tmp/*

WORKDIR /app
ENTRYPOINT ["/entrypoint.sh"]
