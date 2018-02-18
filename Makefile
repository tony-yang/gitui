.DEFAULT_GOAL := start

start:
	docker-compose build gitui
	docker-compose up -d

stop:
	docker-compose down

restart: stop start

test:
	docker build -t gitui .
	docker run --rm gitui bash -c "cd gitui/gitui && bundle install && rails test"
