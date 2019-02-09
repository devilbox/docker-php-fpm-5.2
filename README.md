# PHP-FPM 5.2

[![Build Status](https://travis-ci.org/devilbox/docker-php-fpm-5.2.svg?branch=master)](https://travis-ci.org/devilbox/docker-php-fpm-5.2)
[![Tag](https://img.shields.io/github/tag/devilbox/docker-php-fpm-5.2.svg)](https://github.com/devilbox/docker-php-fpm-5.2/releases)
[![Gitter](https://badges.gitter.im/devilbox/Lobby.svg)](https://gitter.im/devilbox/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
[![Discourse](https://img.shields.io/discourse/https/devilbox.discourse.group/status.svg?colorB=%234CB697)](https://devilbox.discourse.group)
[![](https://images.microbadger.com/badges/version/devilbox/php-fpm-5.2.svg)](https://microbadger.com/images/devilbox/php-fpm-5.2 "php-fpm-5.2")
[![](https://images.microbadger.com/badges/image/devilbox/php-fpm-5.2.svg)](https://microbadger.com/images/devilbox/php-fpm-5.2 "php-fpm-5.2")
[![License](https://img.shields.io/badge/license-MIT-%233DA639.svg)](https://opensource.org/licenses/MIT)

This repository will provide you a fully functional PHP-FPM 5.2.17 Docker image built from [official sources](http://museum.php.net) nightly. Additional patches have been applied to enable FPM functionality. PHP 5.2 [reached EOL](https://secure.php.net/eol.php) on 06 Jan 2011 and thus, official docker support was dropped. It provides the base for [Devilbox PHP-FPM Docker images](https://github.com/devilbox/docker-php-fpm).

| Docker Hub | Upstream Project |
|------------|------------------|
| <a href="https://hub.docker.com/r/devilbox/php-fpm-5.2"><img height="82px" src="http://dockeri.co/image/devilbox/php-fpm-5.2" /></a> | <a href="https://github.com/cytopia/devilbox" ><img height="82px" src="https://raw.githubusercontent.com/devilbox/artwork/master/submissions_banner/cytopia/01/png/banner_256_trans.png" /></a> |

## Similar Base Images

Have a look at the following similar Devilbox base images for which no official versions exist yet:

* [PHP-FPM 5.3](https://github.com/devilbox/docker-php-fpm-5.3)
* [PHP-FPM 7.4](https://github.com/devilbox/docker-php-fpm-7.4)
* [PHP-FPM 8.0](https://github.com/devilbox/docker-php-fpm-8.0)

In case you are looking for development and production ready PHP-FPM images for all versions,
which have a vast amount of modules enabled by default go here:

* [PHP-FPM](https://github.com/devilbox/docker-php-fpm)

## Documentation

In case you seek help, go and visit the community pages.

<table width="100%" style="width:100%; display:table;">
 <thead>
  <tr>
   <th width="33%" style="width:33%;"><h3><a target="_blank" href="https://devilbox.readthedocs.io">Documentation</a></h3></th>
   <th width="33%" style="width:33%;"><h3><a target="_blank" href="https://gitter.im/devilbox/Lobby">Chat</a></h3></th>
   <th width="33%" style="width:33%;"><h3><a target="_blank" href="https://devilbox.discourse.group">Forum</a></h3></th>
  </tr>
 </thead>
 <tbody style="vertical-align: middle; text-align: center;">
  <tr>
   <td>
    <a target="_blank" href="https://devilbox.readthedocs.io">
     <img title="Documentation" name="Documentation" src="https://raw.githubusercontent.com/cytopia/icons/master/400x400/readthedocs.png" />
    </a>
   </td>
   <td>
    <a target="_blank" href="https://gitter.im/devilbox/Lobby">
     <img title="Chat on Gitter" name="Chat on Gitter" src="https://raw.githubusercontent.com/cytopia/icons/master/400x400/gitter.png" />
    </a>
   </td>
   <td>
    <a target="_blank" href="https://devilbox.discourse.group">
     <img title="Devilbox Forums" name="Forum" src="https://raw.githubusercontent.com/cytopia/icons/master/400x400/discourse.png" />
    </a>
   </td>
  </tr>
  <tr>
  <td><a target="_blank" href="https://devilbox.readthedocs.io">devilbox.readthedocs.io</a></td>
  <td><a target="_blank" href="https://gitter.im/devilbox/Lobby">gitter.im/devilbox</a></td>
  <td><a target="_blank" href="https://devilbox.discourse.group">devilbox.discourse.group</a></td>
  </tr>
 </tbody>
</table>

## Build

```bash
# Build the Docker image locally
make build

# Rebuild the Docker image locally without cache
make rebuild

# Test the Docker image after building
make test
```

## Usage

Add the following `FROM` line into your Dockerfile:

```dockerfile
FROM devilbox/php-fpm-5.2:latest
```

## Available Modules

If you need a dockerized version of **PHP 5.2** or **PHP-FPM 5.2** which provides a vast amount of
modules enabled by default visit: **[devilbox/docker-php-fpm](https://github.com/devilbox/docker-php-fpm)**

<!-- modules -->
| Module       | Built-in  |
|--------------|-----------|
| Core         | ✔         |
| ctype        | ✔         |
| curl         | ✔         |
| date         | ✔         |
| dom          | ✔         |
| ereg         | ✔         |
| fileinfo     | ✔         |
| filter       | ✔         |
| hash         | ✔         |
| iconv        | ✔         |
| json         | ✔         |
| libxml       | ✔         |
| mysql        | ✔         |
| mysqlnd      | ✔         |
| openssl      | ✔         |
| pcre         | ✔         |
| PDO          | ✔         |
| pdo_sqlite   | ✔         |
| Phar         | ✔         |
| posix        | ✔         |
| readline     | ✔         |
| recode       | ✔         |
| Reflection   | ✔         |
| session      | ✔         |
| SimpleXML    | ✔         |
| SPL          | ✔         |
| SQLite       | ✔         |
| sqlite3      | ✔         |
| standard     | ✔         |
| tokenizer    | ✔         |
| xml          | ✔         |
| xmlreader    | ✔         |
| xmlwriter    | ✔         |
| zlib         | ✔         |
<!-- /modules -->

## Example

Create a temporary directory, navigate into it and copy/paste the commands below to get started.

#### 1. Setup hello world webpage
```bash
mkdir htdocs
echo "<?php echo 'hello world';" > htdocs/index.php
```

#### 2. Start PHP container
```bash
docker run -d --rm --name devilbox-php-fpm-5-2 \
  -v $(pwd)/htdocs:/var/www/default/htdocs devilbox/php-fpm-5.2
```

#### 3. Start Nginx container
```bash
docker run -d --rm --name devilbox-nginx-stable \
  -v $(pwd)/htdocs:/var/www/default/htdocs \
  -e PHP_FPM_ENABLE=1 \
  -e PHP_FPM_SERVER_ADDR=devilbox-php-fpm-5-2 \
  -p 8080:80 \
  --link devilbox-php-fpm-5-2 \
  devilbox/nginx-stable
```

#### 4. Open browser

Open up your browser at http://127.0.0.1:8080

## Limitations

| Web server     | Status                               | Comments                                         |
|----------------|--------------------------------------|--------------------------------------------------|
| Apache 2.2     | Fails with `no input file specified` | -                                                |
| Apache 2.4     | works                                | Access/Error log via stdout/stderr or file works |
| Nginx stable   | works                                | Access/Error log via stdout/stderr or file works |
| Nginx mainline | works                                | Access/Error log via stdout/stderr or file works |

## Todo

* Make PHP-FPM 5.2 work with Apache 2.2

## License

**[MIT License](LICENSE)**

Copyright (c) 2018 [cytopia](https://github.com/cytopia)
