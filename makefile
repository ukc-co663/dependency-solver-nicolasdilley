all: compile

compile: deps
	./compile.sh

deps:
	./install_deps.sh

test: compile
	./run_tests.sh

.PHONY: all compile test