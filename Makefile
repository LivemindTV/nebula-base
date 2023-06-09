IMAGE=nebulabroadcast/nebula-base:6.1
PHONY: build shell dist

build:
	docker build -t $(IMAGE) .

shell:
	docker run --rm -it  $(IMAGE) /bin/bash

dist: build
	docker push $(IMAGE)
