#!/usr/bin/env bash


###
### Variables
###
WWW_PORT="81"
DOC_ROOT_HOST="$( mktemp -d )"
DOC_ROOT_CONT="/var/www/default"

CONFIG_HOST="$( mktemp -d )"
CONFIG_CONT="/etc/nginx/conf.d"

NAME_PHP="devilbox-php-fpm-5-2"
CONT_PHP="devilbox/php-fpm-5.2:latest"

NAME_WEB="nginx-stable-devilbox"
CONT_WEB="nginx:stable"


###
### Create required files
###

# PHP Index File
{
	echo '<?php'
	echo '$array = array("i", "t", "w", "o", "r", "k", "s");'
	echo 'for ($i=0; $i<count($array); $i++) {'
	echo '    printf("%s", $array[$i]);'
	echo '}'
	echo 'printf("\n");'
} > "${DOC_ROOT_HOST}/index.php"
# PHP Error File
{
	echo '<?php'
	echo 'echo "should give errors";'
	echo '$array = ;'
	echo 'test'
} > "${DOC_ROOT_HOST}/error.php"

# Nginx conf
{
	echo "server {"
	echo "    server_name _;"
	echo "    listen 80;"
	echo "    root ${DOC_ROOT_CONT};"
	echo "    index index.php;"
	echo "    location ~* \.php\$ {"
	echo "        fastcgi_index index.php;"
	echo "        fastcgi_pass ${NAME_PHP}:9000;"
	echo "        include fastcgi_params;"
	echo "        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;"
	echo "        fastcgi_param SCRIPT_NAME     \$fastcgi_script_name;"
	echo "    }"
	echo "}"
} > "${CONFIG_HOST}/php.conf"


###
### Fix mount permissions
###
chmod 0777 "${CONFIG_HOST}"
chmod 0777 "${DOC_ROOT_HOST}"
chmod 0644 "${DOC_ROOT_HOST}/index.php"
chmod 0644 "${DOC_ROOT_HOST}/error.php"


###
### Start containers
###
PHP_DID="$( docker run -d --name ${NAME_PHP} -v ${DOC_ROOT_HOST}:${DOC_ROOT_CONT} ${CONT_PHP} )"
sleep 2
WEB_DID="$( docker run -d --name ${NAME_WEB} -v ${DOC_ROOT_HOST}:${DOC_ROOT_CONT} -v ${CONFIG_HOST}:${CONFIG_CONT} -p ${WWW_PORT}:80 --link ${NAME_PHP} ${CONT_WEB} )"
sleep 2


###
### Test PHP ini
###
#docker exec "${PHP_DID}"

###
### Test for PHP success
###
FAILED=0
echo "[TEST] curl index.php:"
echo "------------------------------------"
if ! curl 127.0.0.1:${WWW_PORT}/index.php 2>/dev/null | grep 'itworks'; then
	echo "[FAILED], gathering info"
	echo

	echo "index.php:"
	echo "------------------------------------"
	cat "${DOC_ROOT_HOST}/index.php"
	echo

	echo "curl:"
	echo "------------------------------------"
	curl 127.0.0.1:${WWW_PORT}/index/php
	echo

	echo "docker logs php"
	echo "------------------------------------"
	docker logs "${PHP_DID}"
	echo

	echo "docker logs web"
	echo "------------------------------------"
	docker logs "${WEB_DID}"
	echo
	FAILED=1
fi
echo


###
### Test for PHP errors
###
echo "[TEST] curl error.php:"
echo "------------------------------------"
curl 127.0.0.1:${WWW_PORT}/error.php 2>/dev/null
sleep 2
echo
docker logs "${PHP_DID}"
docker logs "${WEB_DID}"
docker exec "${PHP_DID}" ls -lap /usr/local/logs
docker exec "${PHP_DID}" ls -lap /var/log

docker exec "${PHP_DID}" php ${DOC_ROOT_CONT}/error.php
docker logs "${PHP_DID}"
docker logs "${WEB_DID}"
docker exec "${PHP_DID}" ls -lap /usr/local/logs
docker exec "${PHP_DID}" ls -lap /var/log


#docker exec "${PHP_DID}" cat /usr/local/logs/fpm.err
#docker exec "${PHP_DID}" cat /usr/local/logs/err.log
###
### Clean-up
###
docker stop "${WEB_DID}"
docker stop "${PHP_DID}"

docker rm -f "${NAME_WEB}"
docker rm -f "${NAME_PHP}"

if [ "${FAILED}" -ne "0" ]; then
	exit 1
fi

exit 0
