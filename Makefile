.PHONY: build test

build:
	docker build -t devilbox/php-fpm-5.2 .

test:
	./test/test.sh
