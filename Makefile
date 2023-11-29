test:
	zig build test

release:
	zig build run -Doptimize=ReleaseSmall