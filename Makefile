.DEFAULT_GOAL := start

start:
	docker-compose build gitui
	docker-compose up -d

stop:
	docker-compose down

restart: stop start
