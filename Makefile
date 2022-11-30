# Frontend to dune.

CURRENT_DIR := $(shell pwd)
BIN_DIR := $(CURRENT_DIR)/_build/install/default/bin
BIN_LIST := micse micse.naive_trxpath_main micse.naive_prover micse.naive_refuter micse-s micse-s.enhanced_prover check_grammar
QUIET := > /dev/null

.PHONY: default build install uninstall test clean

default: build

build:
	dune build --build-dir $(PWD)/_build
	mkdir -p $(CURRENT_DIR)/bin $(QUIET)
	cp -f $(foreach file,$(BIN_LIST),$(BIN_DIR)/$(file)) $(CURRENT_DIR)/bin $(QUIET)

test:
	dune build
	dune runtest -f

install:
	dune install

uninstall:
	dune uninstall

clean:
	dune clean
	rm -rf ./bin $(QUIET)
# Optionally, remove all files/folders ignored by git as defined
# in .gitignore (-X).
	git clean -dfXq