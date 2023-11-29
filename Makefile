test:
	zig build test

build-debug:
	zig build -Doptimize=Debug

build-release:
	zig build -Doptimize=ReleaseFast

zig-out/bin/generate-file: src/generate-file.zig
	zig build generate

test_file/1.txt: zig-out/bin/generate-file
	mkdir -p test_file
	./zig-out/bin/generate-file

debug: build-debug test_file/1.txt
	./zig-out/bin/tinyficator ./test_file/1.txt

release: build-release generate
	./zig-out/bin/tinyficator ./test_file/1.txt
