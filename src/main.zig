const std = @import("std");
const parser = @import("parser.zig");

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

    var new_file = try allocator.alloc(u8, file.len + 4);
    defer allocator.free(new_file);
    std.mem.copy(u8, new_file[0..], file);
    std.mem.copy(u8, new_file[file.len..], ".asm");

    var r = parser.fileParse(allocator, result).parse();
    const p = r.reader();
    var write = try std.fs.cwd().createFile(new_file, .{});
    defer write.close();

    var block = try allocator.alloc(u8, 4 * 1024);
    defer allocator.free(block);
    while (true) {
        const read = try p.read(block[0..]);
        if (read == 0) {
            break;
        }
        _ = try write.write(block[0..read]);
    }

    std.debug.print("File size: {d}\n", .{file_size});
}
