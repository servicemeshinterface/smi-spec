
HAS_MDLINT := $(shell command -v markdownlint;)

.PHONY: lint
lint:
	@# lint the markdown
ifndef HAS_MDLINT
	sudo npm install -g markdownlint-cli
endif
	markdownlint -c .markdownlint.yaml .
