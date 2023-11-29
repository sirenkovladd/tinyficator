const std = @import("std");

pub fn main() !void {
    // generate random content for file test_file/1.txt

    var f = try std.fs.cwd().createFile("test_file/1.txt", .{});
    defer f.close();

    var rr = std.rand.DefaultPrng.init(0);
    var rng = rr.random();
    const from: u8 = 32;
    const to: u8 = 126;
    const extra = [_]u8{ '\n', '\r', '\t' };
    for (0..1024) |_| {
        var buf: [1024]u8 = undefined;
        for (&buf) |*elem| {
            elem.* = q: {
                const r: u8 = rng.int(u8) % (to - from + @as(u8, extra.len));
                if (r < to - from) {
                    break :q from + r;
                } else {
                    break :q extra[r - (to - from)];
                }
            };
        }
        _ = try f.write(buf[0..]);
    }
}
