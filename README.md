# PHP 5.2 FPM

[![Build Status](https://travis-ci.org/devilbox/docker-php-fpm-5.2.svg?branch=master)](https://travis-ci.org/devilbox/docker-php-fpm-5.2)

PHP 5.2.17 with latest patches to make PHP-FPM work.


## Setup instructions

Create a temporary directory, navigate into it and copy/paste the commands below to get started.


#### 1. Setup hello world webpage
```bash
mkdir htdocs
echo "<?php echo 'hello world';" > htdocs/index.php
```

#### 2. Start PHP container
```
docker run -d --name devilbox-php-fpm-5-2 \
  -v $(pwd)/htdocs:/var/www/default/htdocs devilbox/php-fpm-5.2
```

#### 3. Start Nginx container
```
docker run -d --name devilbox-nginx-stable \
  -v $(pwd)/htdocs:/var/www/default/htdocs \
  -e PHP_FPM_ENABLE=1 \
  -e PHP_FPM_SERVER_ADDR=devilbox-php-fpm-5-2 \
  -p 8080:80 \
  --link devilbox-php-fpm-5-2 \
  devilbox/nginx-stable
```

#### 4. Open browser

Open up your browser at http://127.0.0.1:8080


## Known issues

* PHP-FPM 5.2 will return a blank page if any php error occured in your `*.php` files.  There won't be any file or docker logs showing the error.
* PHP-FPM 5.2 currently only works with Nginx (Apache returns `No input file`)


## Todo

* Make PHP-FPM 5.2 show errors on page instead of returning white page.
* Make PHP-FPM 5.2 work with Apache
