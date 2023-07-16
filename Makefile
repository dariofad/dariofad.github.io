.phony: deploy

all: deploy

deploy:
	git checkout gh-pages
	rm -rf public/*
	touch public/.nojekyll
	zola build
	git push
	git checkout master
