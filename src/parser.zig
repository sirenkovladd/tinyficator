const std = @import("std");
const Parser = @This();

file: std.fs.File.Reader,
allocator: std.mem.Allocator,

const ParsedFile = struct {
    header: []u8,
    r: std.fs.File.Reader,

    pub fn init(header: []u8, r: std.fs.File.Reader) ParsedFile {
        const ret = ParsedFile{ .header = header, .r = r };
        return ret;
    }

    pub fn reader(self: *const ParsedFile) std.io.AnyReader {
        return self.r.any();
    }
};

const NeedParsed = struct {
    allocator: std.mem.Allocator,
    file: std.fs.File,

    pub fn init(allocator: std.mem.Allocator, r: std.fs.File) NeedParsed {
        return NeedParsed{ .allocator = allocator, .file = r };
    }

    pub fn parse(self: NeedParsed) ParsedFile {
        const r = self.file.reader();
        const ret = ParsedFile.init(&[_]u8{}, r);
        return ret;
    }
};

pub fn fileParse(allocator: std.mem.Allocator, r: std.fs.File) NeedParsed {
    return NeedParsed.init(allocator, r);
}
