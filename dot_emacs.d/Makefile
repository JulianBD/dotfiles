EMACS ?= emacs
EMACS_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
BATCH := $(EMACS) --batch \
	--eval '(setq user-emacs-directory "$(EMACS_DIR)")' \
	--eval '(add-to-list (quote load-path) (expand-file-name "modules" user-emacs-directory))'

.PHONY: generate scrape clean

## Generate elisp from config JSON files
generate:
	$(BATCH) -l me-contract -l me-defaults-atoms -l me-scopes \
		-f me-contract-generate

## Scrape installed package API surfaces to scraped/*.org
scrape:
	$(BATCH) -l early-init.el -l init.el -l scrape-defs.el

## Remove generated files (regenerate with `make generate`)
clean:
	rm -f generated/me-generated-*.el
	rm -f scraped/*.org
