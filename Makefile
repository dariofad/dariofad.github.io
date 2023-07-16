.phony: build

all: build

build:
	touch public/.nojekyll
	zola build
	cp -r public docs
