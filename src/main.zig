const std = @import("std");
const parser = @import("parser.zig");

const t = enum { enc, dec };

fn getType(typ: []const u8) !t {
    if (std.mem.eql(u8, typ, "enc")) {
        return .enc;
    } else if (std.mem.eql(u8, typ, "dec")) {
        return .dec;
    } else {
        std.debug.print("Unknown type: {s}\n", .{typ});
        return error.InvalidType;
    }
}

pub fn main() !void {
    const allocator = std.heap.c_allocator;
    const iter = try std.process.argsAlloc(allocator);

    if (iter.len == 1) {
        std.debug.print("Usage: {s} (enc|dec) [args]\n", .{iter.ptr[0]});
        return;
    }

    const typ = getType(iter.ptr[1]) catch return;

    if (iter.len > 3) {
        std.debug.print("Too many args!\n", .{});
        return;
    }

    const file = iter.ptr[2];
    switch (typ) {
        .enc => try encode(allocator, file),
        .dec => try decode(allocator, file),
    }
}

fn encode(allocator: std.mem.Allocator, file: []const u8) !void {
    var result = std.fs.cwd().openFile(file, .{}) catch |err| {
        std.debug.print("Error opening file: {}\n", .{err});
        return;
    };
    defer result.close();

    const file_size = try result.getEndPos();

    var new_file = try allocator.alloc(u8, file.len + 4);
    defer allocator.free(new_file);
    std.mem.copy(u8, new_file[0..], file);
    std.mem.copy(u8, new_file[file.len..], ".asm");

    var r = try parser.fileParse(allocator, result).parse(&[_]u8{
        4, 6, 8, 10, 12, 14, 16, 18, 20,
    });
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

fn decode(allocator: std.mem.Allocator, file: []const u8) !void {
    _ = allocator;
    _ = file;

    std.log.err("Not implemented yet!\n", .{});
}
