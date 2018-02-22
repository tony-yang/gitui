.DEFAULT_GOAL := start

start:
	docker-compose build gitui
	docker-compose up -d

stop:
	docker-compose down

restart: stop start

prod-start:
	sudo docker-compose build gitui
	sudo docker-compose up -d

prod-stop:
	sudo docker-compose down

prod-restart: prod-stop prod-start

test:
	docker build -t gitui .
	docker run --rm gitui bash -c "cd gitui/gitui && bundle install && rails test"
