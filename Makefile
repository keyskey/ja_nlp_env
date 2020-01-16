NAME=ja_nlp-env
VERSION=1.0

build:
	docker build -t $(NAME):$(VERSION) .

run:
	docker run --rm -p 8888:8888 -v `pwd`:/home/work $(NAME):$(VERSION) jupyter lab --allow-root --port=8888 --ip=0.0.0.0 --no-browser

setup:
	mkdir datas notebooks
