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
		dpkg-dev \
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
	&& curl -sS -k -L --fail "https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz" -o openssl.tar.gz \
	&& curl -sS -k -L --fail "https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz.asc" -o openssl.tar.gz.asc \
	&& tar -xzf openssl.tar.gz -C openssl --strip-components=1 \
	&& cd /tmp/openssl \
	\
	# Fix libs for i386
	&& if [ "$(dpkg-architecture  --query DEB_HOST_ARCH)" = "i386" ]; then \
		ls -1p "/usr/include/$(dpkg-architecture --query DEB_BUILD_MULTIARCH)/" \
			| grep '/$' \
			| xargs -n1 sh -c 'ln -s "/usr/include/$(dpkg-architecture --query DEB_BUILD_MULTIARCH)/${1}" "/usr/include/"' -- || true; \
		touch /usr/include/gnu/stubs-64.h; \
		ls -1 "/usr/lib/$(dpkg-architecture --query DEB_BUILD_MULTIARCH)/" \
			| xargs -n1 sh -c 'ln -s "/usr/lib/$(dpkg-architecture --query DEB_BUILD_MULTIARCH)/${1}" "/usr/lib/"' -- || true; \
	fi \
	\
	&& ./config \
	&& make depend \
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
	&& curl -sS -k -L --fail "http://museum.php.net/php5/php-${PHP_VERSION}.tar.gz" -o /usr/src/php.tar.gz \
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
	&& docker-php-source extract \
	&& cd /usr/src/php \
	&& gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
	&& debMultiarch="$(dpkg-architecture --query DEB_BUILD_MULTIARCH)" \
	\
	# Fix libmariadbclient lib location
	&& find /usr/lib/ -name '*mariadbclient*' | xargs -n1 sh -c 'ln -s "${1}" "/usr/lib/$( basename "${1}" | sed "s|libmariadbclient|libmysqlclient|g" )"' -- \
	\
	# https://bugs.php.net/bug.php?id=74125
	&& if [ ! -d /usr/include/curl ]; then \
		ln -sT "/usr/include/$debMultiarch/curl" /usr/local/include/curl; \
	fi \
	\
	&& ./configure \
		--host="${gnuArch}" \
		#--with-libdir="${debMultiarch}" \
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
