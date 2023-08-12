.phony: build serve install clean

POLICY := boxer/zola.json

all: clean | install build

_clean_boxer:
	$(info [*] Clean boxer)
	@cd boxer; cargo clean

install:
	$(info [*] Check zola is installed)
	@zola --version
	$(info [*] Build the sandboxer)
	@cd boxer; cargo build

_clean_website:
	$(info [*] Clean website)
	@rm -rf docs/*

build: _clean_website
	$(info [*] Unset environment variables & rebuild website)
	@./boxer/subshell.sh $@ $(POLICY)

serve: _clean_website
	@echo "\033[0;31mWriter mode: you can preview the website but no protection is available"
	@zola serve

clean: _clean_website _clean_boxer
