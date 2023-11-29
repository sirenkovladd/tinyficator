test: src/*.zig
	zig build test

zig-out/bin/tinyficator-debug: src/*.zig
	zig build -Doptimize=Debug

zig-out/bin/tinyficator: src/*.zig
	zig build -Doptimize=ReleaseFast

test_file/1.txt: src/generate-file.zig
	mkdir -p test_file
	zig build generate

debug: zig-out/bin/tinyficator-debug test_file/1.txt
	./zig-out/bin/tinyficator-debug ./test_file/1.txt

release: zig-out/bin/tinyficator genertest_file/1.txtate
	./zig-out/bin/tinyficator ./test_file/1.txt