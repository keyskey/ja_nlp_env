NAME=my-nlp-notebook
VERSION=1.0

build:
	docker build -t $(NAME):$(VERSION) .

run:
	docker run --rm -p 8888:8888 -e JUPYTER_ENABLE_LAB=yes -e TZ=Asia/Tokyo -v `pwd`:/home/jovyan/work $(NAME):$(VERSION)
