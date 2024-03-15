INST_PREFIX ?= /usr
INST_LIBDIR ?= $(INST_PREFIX)/lib/lua/5.1
INST_LUADIR ?= $(INST_PREFIX)/share/lua/5.1
INSTALL ?= install
RUST_LIB_PREFIX ?= ./prefix-trie


### lint:         Lint Lua source code
.PHONY: lint
lint:
	luacheck -q resty

### test:         Run test suite. Use test=... for specific tests
.PHONY: test
test:
	TEST_NGINX_LOG_LEVEL=info \
	prove -I. -I../test-nginx/lib -r t/


### install:      Install the library to runtime
.PHONY: install
install:
	$(INSTALL) -d $(INST_LUADIR)/resty/
	$(INSTALL) resty/*.lua $(INST_LUADIR)/resty/

PLATFORM := $(shell uname)

ifeq ($(PLATFORM), Linux)
    C_SO_NAME := libipmatcher.so
else ifeq ($(PLATFORM), Darwin)
    C_SO_NAME := libipmatcher.dylib
endif

### clean:        Remove generated files
.PHONY: clean
clean:
	rm -f $(C_SO_NAME)
	cargo clean --manifest-path=$(RUST_LIB_PREFIX)/Cargo.toml

compile: 
	cargo build -r --manifest-path=$(RUST_LIB_PREFIX)/Cargo.toml
	
ifeq ($(PLATFORM), Linux)
	cp $(RUST_LIB_PREFIX)/target/release/$(C_SO_NAME) .
else ifeq ($(PLATFORM), Darwin)
	cp $(RUST_LIB_PREFIX)/target/release/$(C_SO_NAME) .
else
	$(error Unsupported platform: $(PLATFORM))
endif

### help:         Show Makefile rules
.PHONY: help
help:
	@echo Makefile rules:
	@echo
	@grep -E '^### [-A-Za-z0-9_]+:' Makefile | sed 's/###/   /'
