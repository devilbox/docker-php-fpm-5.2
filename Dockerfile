FROM debian:stretch
MAINTAINER "cytopia" <cytopia@everythingcli.org>

ENV PHP_VERSION 5.2.17
ENV PHP_INI_DIR /usr/local/etc/php

ENV BUILD_DEPS \
		autoconf2.13 \
		libbison-dev \
		libcurl4-openssl-dev \
		libfl-dev \
		libmariadbclient-dev-compat \
		libpcre3-dev \
		libreadline6-dev \
		librecode-dev \
		libsqlite3-dev \
		libssl-dev \
		libxml2-dev \
		patch


# Setup directories
RUN set -eux \
	&& mkdir -p ${PHP_INI_DIR}/conf.d \
	&& mkdir -p /usr/src/php


# persistent / runtime deps
RUN set -eux \
	&& apt-get update && apt-get install -y --no-install-recommends \
		ca-certificates \
		curl \
		libpcre3 \
		librecode0 \
		libmariadbclient18 \
		libsqlite3-0 \
		libxml2 \
	&& apt-get clean \
	&& rm -r /var/lib/apt/lists/*


# phpize deps
RUN set -eux \
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


# compile openssl, otherwise --with-openssl won't work
RUN set -eux \
	&& OPENSSL_VERSION="1.0.2g" \
	&& cd /tmp \
	&& mkdir openssl \
	&& update-ca-certificates \
	&& curl -skL "https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz" -o openssl.tar.gz \
	&& curl -skL "https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz.asc" -o openssl.tar.gz.asc \
	&& tar -xzf openssl.tar.gz -C openssl --strip-components=1 \
	&& cd /tmp/openssl \
	#\
	## Fix curl lib location from '/usr/include/x86_64-linux-gnu/curl' to '/usr/include/curl'
	#&& if [ "$(dirname $(dirname $(find / -name 'easy.h')))" != "/usr/include" ]; then \
	#	ln -s "$(dirname $(dirname $(find / -name 'easy.h')))/curl" /usr/include/curl; \
	#fi \
	#\
	## Fix cdefs.h
	#&& if [ "$(dirname $(dirname $(find / -name 'cdefs.h')))" != "/usr/include" ]; then \
	#	ln -s "$(dirname $(dirname $(find / -name 'cdefs.h')))/sys" /usr/include/sys; \
	#fi \
	#\
	## Fix wordsize.h
	#&& if [ "$(dirname $(dirname $(find / -name 'wordsize.h')))" != "/usr/include" ]; then \
	#	ln -s "$(dirname $(dirname $(find / -name 'wordsize.h')))/bits" /usr/include/bits; \
	#fi \
	#\
	## Fix stubs.h
	#&& if [ "$(dirname $(dirname $(find / -name 'stubs.h')))" != "/usr/include" ]; then \
	#	ln -s "$(dirname $(dirname $(find / -name 'stubs.h')))/gnu" /usr/include/gnu; \
	#fi \
	#&& if [ ! -f /usr/include/gnu/stubs-64.h ]; then \
	#	touch /usr/include/gnu/stubs-64.h; \
	#fi \
	#\
	## Fix errno.h
	#&& if [ "$(dirname $(dirname $(find / -name 'errno.h' | grep 'asm/')))" != "/usr/include" ]; then \
	#	ln -s "$(dirname $(dirname $(find / -name 'errno.h' | grep 'asm/')))/asm" /usr/include/asm; \
	#fi \
	#\
	&& ./config \
	\
	## Fix libs
	#ln -s $( find /usr/lib/ -type d -name '*-linux-*' | grep -vE '(/.*){4}' )/*	/usr/lib/ || true \
	\
	#&& if [ ! -f /usr/include/libio.h ]; then \
	#	ln -s /usr/include/libio.h /usr/include/bio.h; \
	#fi \
	\
	&& make -j"$(nproc)" \
	&& make install \
	&& rm -rf /tmp/openssl*


# php 5.2 needs older autoconf
RUN set -eux \
	&& set -x \
	&& apt-get update \
	&& apt-get install -y ${BUILD_DEPS} --no-install-recommends \
	&& rm -rf /var/lib/apt/lists/*


# Copy and apply patches to PHP
COPY data/php-${PHP_VERSION}*.patch /tmp/
RUN set -eux \
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


COPY data/docker-php-source /usr/local/bin/
RUN set -eux \
	&& apt update && apt install flex -y \
	\
	# Fix libmariadbclient lib location
	&& find /usr/lib/ -name '*mariadbclient*' | xargs -n1 sh -c 'ln -s "${1}" "/usr/lib/$( basename "${1}" | sed "s|libmariadbclient|libmysqlclient|g" )"' -- \
	#&& ln -s $(dirname $(find /usr/lib/ -name 'libmariadbclient*' | head -1))/libmariadbclient* /usr/lib/ \
	\
	# Fix curl lib location from '/usr/include/x86_64-linux-gnu/curl' to '/usr/include/curl'
	&& if [ "$(dirname $(dirname $(find / -name 'easy.h')))" != "/usr/include" ]; then \
		ln -s "$(dirname $(dirname $(find / -name 'easy.h')))/curl" /usr/include/curl; \
	fi \
	\
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
	&& php -v \
# Clean-up
	&& { find /usr/local/bin /usr/local/sbin -type f -executable -exec strip --strip-all '{}' + || true; } \
	&& apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false -o APT::AutoRemove::SuggestsImportant=false ${BUILD_DEPS} \
	&& make clean \
	&& cd / \
	&& docker-php-source delete


WORKDIR /var/www/html
COPY data/docker-php-* /usr/local/bin/
COPY data/php-fpm /usr/local/sbin/php-fpm
COPY data/php-fpm.conf /usr/local/etc/
COPY data/php.ini /usr/local/etc/php/php.ini


EXPOSE 9000
ENTRYPOINT ["php-fpm"]
