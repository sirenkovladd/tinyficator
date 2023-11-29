const std = @import("std");

pub fn main() !void {
    const allocator = std.heap.c_allocator;

    const iter = try std.process.argsAlloc(allocator);

    if (iter.len == 1) {
        std.debug.print("Usage: {s} [args]\n", .{iter.ptr[0]});
        return;
    }

    if (iter.len > 2) {
        std.debug.print("Too many args!\n", .{});
        return;
    }

    const file = iter.ptr[1];

    var result = try std.fs.cwd().openFile(file, .{});
    defer result.close();

    const file_size = try result.getEndPos();

    std.debug.print("File size: {d}\n", .{file_size});
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
