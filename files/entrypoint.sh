#!/usr/bin/env bash

set -e

if [[ ! -f /etc/.setupdone ]]; then

	# RUN INITIAL SETUP
	USERGROUP=${USERGROUP:-$USERNAME}
	RANDPASS=$(date | md5sum | awk '{print $1}')
	addgroup -g 1000 $USERGROUP
	adduser -D -u 1000 -h /app -s /bin/bash -G $USERGROUP $USERNAME
	echo "${USERNAME}:${RANDPASS}" | chpasswd &> /dev/null
	echo " "

	if [[ ! -f /usr/local/bin/composer ]]; then
		echo "=========================================================="
		echo " INSTALL COMPOSER"
		echo "=========================================================="
		curl -o /usr/local/bin/composer https://getcomposer.org/download/$COMPOSER_VERSION/composer.phar
		chmod +x /usr/local/bin/composer
		mkdir -p /app/.composer/vendor/bin
		chown -R $USERNAME:$USERGROUP /app/.composer
		echo " "
	fi

	# SETUP NGINX
	echo "=========================================================="
	echo " SETUP NGINX"
	echo "=========================================================="
	mkdir -p /var/cache/nginx
	chown -R $USERNAME:$USERGROUP /var/lib/nginx
	chown -R $USERNAME:$USERGROUP /var/log/nginx
	chown -R $USERNAME:$USERGROUP /var/cache/nginx
	echo "Creating nginx.conf from template..."
	sed -ri "s|USERNAME|${USERNAME}|g" /etc/nginx/nginx.conf
    sed -ri "s|DOMAIN|${DOMAIN}|g" /etc/nginx/nginx.conf
	sed -ri "s|REAL_IP_FROM|${REAL_IP_FROM}|" /etc/nginx/nginx.conf
	echo "Nginx ready with domain: ${DOMAIN}"
	echo " "

	# SETUP PHP
	echo "=========================================================="
	echo " SETUP PHP"
	echo "=========================================================="
	mkdir -p /var/lib/php
	chown -R $USERNAME:$USERGROUP /var/lib/php
	rm /usr/local/etc/php-fpm.d/*.conf
    cp /template/www.conf /usr/local/etc/php-fpm.d/www.conf

    OPCACHE_ENABLE=${OPCACHE_ENABLE:-Off}
    PHP_DISPLAY_ERRORS=${PHP_DISPLAY_ERRORS:-On}
    PHP_MEMORY_LIMIT=${PHP_MEMORY_LIMIT:-512M}

	sed -ri "s|USERNAME|${USERNAME}|" /usr/local/etc/php-fpm.d/www.conf
	sed -ri "s|USERGROUP|${USERGROUP}|" /usr/local/etc/php-fpm.d/www.conf
	cp /template/php-override.ini $PHP_INI_DIR/conf.d/00-override.ini
    sed -ri "s|OPCACHE_ENABLE|${OPCACHE_ENABLE}|" $PHP_INI_DIR/conf.d/00-override.ini
    sed -ri "s|PHP_DISPLAY_ERRORS|${PHP_DISPLAY_ERRORS}|" $PHP_INI_DIR/conf.d/00-override.ini
    sed -ri "s|PHP_MEMORY_LIMIT|${PHP_MEMORY_LIMIT}|" $PHP_INI_DIR/conf.d/00-override.ini

	if [[ -f "${PHP_INI_DIR}/php.ini-production" ]]; then
		cp $PHP_INI_DIR/php.ini-production $PHP_INI_DIR/php.ini
	fi

	PHP_CLI_PATH=$(which php)
	echo "PHP Configuration Location: ${PHP_INI_DIR}/php.ini"
    echo "PHP binary path: ${PHP_CLI_PATH}"
	echo " "

	# SETUP CRON
	echo "=========================================================="
	echo " SETUP CRON"
	echo "=========================================================="
	cp /template/crontab /etc/crontabs/$USERNAME
	echo "=== Laravel cron enabled."
	echo "Crontab available at: /etc/crontabs/${USERNAME}"
	echo " "

    # SETUP USER PROFILE AND ACCESS
	echo "=========================================================="
	echo " SETUP PROFILE & NPM"
	echo "=========================================================="
	if [[ ! -d /app/.npm ]]; then
		mkdir -p /app/.npm
		chown -R $USERNAME:$USERGROUP /app/.npm
	fi
	npm config set prefix '/app/.npm'
    export PATH=/app/.npm/bin:$PATH

    [ -d "/app/logs" ] || mkdir -p /app/logs

	cp /template/userprofile /app/.bashrc
	echo ". ~/.bashrc" > /app/.profile
	chown -R $USERNAME:$USERGROUP /app/.bashrc
	chown -R $USERNAME:$USERGROUP /app/.profile
	chown -R $USERNAME:$USERGROUP /app/logs

    echo "NPM  directory is on /app/.npm"
    echo " "

	# MARK CONTAINER AS INSTALLED
	echo "=========================================================="
	echo " SETUP DONE ;) CONTINUE TO SERVICES"
	echo "=========================================================="

    sed -ri "s|USERNAME|${USERNAME}|g" /etc/supervisord.conf

    if [[ -z "${USE_HORIZON}" ]]; then
        sed -i '97,112d' /etc/supervisord.conf
    fi

    if [[ -z "${USE_WEBSOCKET}" ]]; then
        sed -i '82,96d' /etc/supervisord.conf
    fi

	touch /etc/.setupdone
	rm -rf /template
	echo " "
fi

/usr/bin/supervisord -n -c /etc/supervisord.conf

exec "$@"
