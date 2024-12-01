up:
	docker-compose up --build

down:
	docker-compose down

re:
	docker-compose down && docker-compose up --build

up_user_management:
	docker-compose up --build ruby_user_management postgres adminer smtp4dev
