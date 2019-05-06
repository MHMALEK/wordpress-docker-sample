FROM php:7.1-apache

# install the PHP extensions we need
RUN set -ex; \
	\
	apt-get update; \
	apt-get install -y \
		libjpeg-dev \
		libpng-dev \
		zlib1g-dev \
		rsync \
	; \
	rm -rf /var/lib/apt/lists/*; \
	\
	docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr; \
	docker-php-ext-install gd mysqli opcache zip
# TODO consider removing the *-dev deps and only keeping the necessary lib* packages

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=2'; \
		echo 'opcache.fast_shutdown=1'; \
		echo 'opcache.enable_cli=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini

RUN a2enmod rewrite expires

ENV WORDPRESS_VERSION 5.1
RUN set -ex; \
	curl -o wordpress.tar.gz -fSL "https://fa.wordpress.org/wordpress-${WORDPRESS_VERSION}-fa_IR.tar.gz"; \
# upstream tarballs include ./wordpress/ so this gives us /usr/src/wordpress
	tar -xzf wordpress.tar.gz -C /usr/src/; \
	rm wordpress.tar.gz; \
	chown -R www-data:www-data /usr/src/wordpress

COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

RUN sed -i "/Listen 80/c Listen 8080"                     /etc/apache2/ports.conf && \
    sed -i "/<VirtualHost \*:80>/c <VirtualHost \*:8080>" /etc/apache2/sites-enabled/000-default.conf

EXPOSE 8080

RUN touch .htaccess wp-config.php && \
    chown -R root:0 /var/www/html /var/lock/ /var/run/ .htaccess wp-config.php && \
    chmod -R g+w /var/www/html /var/lock/ /var/run/ .htaccess wp-config.php

USER root

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]