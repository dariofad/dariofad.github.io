.phony: build

all: build

build:
	@echo "[*] Building static website"
	zola build
	@echo "[*] Copying sources"
	rm -rf docs
	cp -r public docs
