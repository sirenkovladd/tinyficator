test: src/*.zig
	zig build test

zig-out/bin/tinyficator-debug: src/*.zig
	zig build -Doptimize=Debug

zig-out/bin/tinyficator: src/*.zig
	zig build -Doptimize=ReleaseFast

test_file/1.txt: src/generate-file.zig
	mkdir -p test_file
	zig build generate

build-debug: zig-out/bin/tinyficator-debug

build-release: zig-out/bin/tinyficator

debug: build-debug test_file/1.txt
	./zig-out/bin/tinyficator-debug enc ./test_file/1.txt

release: build-release test_file/1.txt
	./zig-out/bin/tinyficator enc ./test_file/1.txt