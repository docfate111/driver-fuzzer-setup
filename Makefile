all: build run

build: Dockerfile
	docker build . -t syzkaller-docker

run: build
	docker run -it --rm --privileged --network host syzkaller-docker
