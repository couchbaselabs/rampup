all: build-deps

build-deps:
	git submodule update --init
	cd deps/bson && erlc -o ebin -I include src/*.erl
	cd deps/mongodb && erlc -o ebin -I include -I .. src/*.erl

shell:
	erl -pa deps/bson/ebin deps/mongodb/ebin


