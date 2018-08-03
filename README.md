# PHP 5.2 FPM

[![Build Status](https://travis-ci.org/devilbox/docker-php-fpm-5.2.svg?branch=master)](https://travis-ci.org/devilbox/docker-php-fpm-5.2)

PHP 5.2.17 with latest patches to make PHP-FPM work.


## 1. Build
```bash
# Build the Docker image locally
make build

# Rebuild (without cache) the Docker image locally
make rebuild

# Test the Docker image after building
make test
```


## 2. Run instructions

Create a temporary directory, navigate into it and copy/paste the commands below to get started.

#### 1. Setup hello world webpage
```bash
mkdir htdocs
echo "<?php echo 'hello world';" > htdocs/index.php
```

#### 2. Start PHP container
```bash
docker run -d --name devilbox-php-fpm-5-2 \
  -v $(pwd)/htdocs:/var/www/default/htdocs devilbox/php-fpm-5.2
```

#### 3. Start Nginx container
```bash
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


## 3. Limitations

| Web server     | Status                               | Comments                                         |
|----------------|--------------------------------------|--------------------------------------------------|
| Apache 2.2     | Fails with `no input file specified` | -                                                |
| Apache 2.4     | works                                | Access/Error log via stdout/stderr or file works |
| Nginx stable   | works                                | Access/Error log via stdout/stderr or file works |
| Nginx mainline | works                                | Access/Error log via stdout/stderr or file works |

## Todo

* Make PHP-FPM 5.2 work with Apache 2.2
