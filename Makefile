.phony: deploy

all: deploy

deploy:
	git checkout gh-pages
	rm -rf public/*
	mkdir public
	touch public/.nojekyll
	zola build
	git add -A
	git commit -m "Update deployed site"
	git push
	git checkout master
