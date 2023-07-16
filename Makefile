.phony: build

all: build

build:
	mkdir public
	touch public/.nojekyll
	zola build
	cp -r public docs
