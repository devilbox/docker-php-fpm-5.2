FROM debian:jessie
MAINTAINER "cytopia" <cytopia@everythingcli.org>


ENV PHP_VERSION 5.2.17
ENV PHP_INI_DIR /usr/local/etc/php
ENV GPG_KEYS 0B96609E270F565C13292B24C13C70B87267B52D 0A95E9A026542D53835E3F3A7DEC4E69FC9C83D7 0E604491


# Setup directories
RUN set -x \
	&& mkdir -p ${PHP_INI_DIR}/conf.d \
	&& mkdir -p /usr/src/php


# persistent / runtime deps
RUN set -x \
	&& apt-get update && apt-get install -y --no-install-recommends \
		ca-certificates \
		curl \
		libpcre3 \
		librecode0 \
		libmysqlclient-dev \
		libsqlite3-0 \
		libxml2 \
	&& apt-get clean \
	&& rm -r /var/lib/apt/lists/*


# phpize deps
RUN set -x \
	&& apt-get update && apt-get install -y --no-install-recommends \
		autoconf \
		file \
		g++ \
		gcc \
		libc-dev \
		make \
		pkg-config \
		re2c \
		xz-utils \
	&& apt-get clean \
	&& rm -r /var/lib/apt/lists/*


RUN set -xe \
	&& for key in $GPG_KEYS; do \
		gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "${key}"; \
	done


# compile openssl, otherwise --with-openssl won't work
RUN set -x \
	&& OPENSSL_VERSION="1.0.2g" \
	&& cd /tmp \
	&& mkdir openssl \
	&& curl -sL "https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz" -o openssl.tar.gz \
	&& curl -sL "https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz.asc" -o openssl.tar.gz.asc \
	&& gpg --verify openssl.tar.gz.asc \
	&& tar -xzf openssl.tar.gz -C openssl --strip-components=1 \
	&& cd /tmp/openssl \
	&& ./config && make && make install \
	&& rm -rf /tmp/openssl*


# php 5.2 needs older autoconf
RUN set -x \
	&& buildDeps=" \
		autoconf2.13 \
		libbison-dev \
		libcurl4-openssl-dev \
		libfl-dev \
		libmysqlclient-dev \
		libpcre3-dev \
		libreadline6-dev \
		librecode-dev \
		libsqlite3-dev \
		libssl-dev \
		libxml2-dev \
		patch \
	" \
	&& set -x \
	&& apt-get update && apt-get install -y $buildDeps --no-install-recommends && rm -rf /var/lib/apt/lists/*


# Copy and apply patches to PHP
COPY php-${PHP_VERSION}*.patch /tmp/
RUN set -x \
	&& curl -SL "http://museum.php.net/php5/php-${PHP_VERSION}.tar.gz" -o /usr/src/php.tar.gz \
	\
# Extract artifacts
	&& tar -xf /usr/src/php.tar.gz -C /usr/src/php --strip-components=1 \
# Apply patches
	&& cd /usr/src/php \
	&& patch -p1 < /tmp/php-${PHP_VERSION}-libxml2.patch \
	&& patch -p1 < /tmp/php-${PHP_VERSION}-openssl.patch \
	&& patch -p1 < /tmp/php-${PHP_VERSION}-fpm.patch \
	&& patch -p0 < /tmp/php-${PHP_VERSION}-curl.patch || true \
# Create php.tar.xz
	&& cd /usr/src \
	&& tar -cJf php.tar.xz php \
# Clean-up
	&& rm -rf php php.tar.gz \
	&& rm -rf /tmp/php-*


COPY docker-php-source /usr/local/bin/
RUN set -x \
	&& ln -s /usr/lib/x86_64-linux-gnu/libmysqlclient* /usr/lib/ \
	&& cd /usr/src \
	&& docker-php-source extract \
	&& cd /usr/src/php \
	&& ./configure \
		--with-config-file-path="${PHP_INI_DIR}" \
		--with-config-file-scan-dir="${PHP_INI_DIR}/conf.d" \
		--with-fpm-conf="/usr/local/etc/php-fpm.conf" \
		\
		--enable-fastcgi \
		--enable-fpm \
		--enable-force-cgi-redirect \
		\
		--enable-mbstring \
		--enable-pdo \
		--enable-soap \
		\
		--with-curl \
		--with-mysql \
		--with-mysqli \
		--with-openssl=/usr/local/ssl \
		--with-pdo-mysql \
		--with-readline \
		--with-zlib \
	#&& sed -i 's/-lxml2 -lxml2 -lxml2/-lcrypto -lssl/' Makefile \
	&& make -j"$(nproc)" \
	&& make install \
# Clean-up
	&& { find /usr/local/bin /usr/local/sbin -type f -executable -exec strip --strip-all '{}' + || true; } \
	&& apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false -o APT::AutoRemove::SuggestsImportant=false ${buildDeps} \
	&& make clean \
	&& cd / \
	&& docker-php-source delete


WORKDIR /var/www/html
COPY php-fpm.conf /usr/local/etc/
COPY docker-php-* /usr/local/bin/


EXPOSE 9000
CMD ["php-cgi", "--fpm"]
