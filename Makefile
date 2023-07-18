.phony: build

all: build

build:
	@echo "[*] Building static website"
	zola build
	@echo "[*] Copying sources"
	cp -r public docs
