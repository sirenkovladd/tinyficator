const std = @import("std");

pub const ParsedHeader = struct {};

pub const ParsedFile = struct {
    header: ParsedHeader,
    r: std.fs.File.Reader,

    pub fn init(header: ParsedHeader, r: std.fs.File.Reader) ParsedFile {
        const ret = ParsedFile{ .header = header, .r = r };
        return ret;
    }

    pub fn reader(self: *const ParsedFile) std.io.AnyReader {
        return self.r.any();
    }
};

pub const ParserHeader = struct {
    // allocator: std.mem.Allocator,
    // file: std.fs.File,

    pub fn init(allocator: std.mem.Allocator, size: u8) ParserHeader {
        _ = allocator;
        _ = size;

        return ParserHeader{};
    }

    pub fn load(ph: ParserHeader, buffer: []const u8) void {
        _ = ph;
        _ = buffer;
    }

    pub fn finish(ph: ParserHeader) void {
        _ = ph;
    }

    pub fn len(ph: ParserHeader) usize {
        _ = ph;

        return 0;
    }

    pub fn header(ph: ParserHeader) ParsedHeader {
        _ = ph;

        return ParsedHeader{};
    }
};

pub const NeedParsed = struct {
    const Error = std.mem.Allocator.Error || std.fs.File.Reader.Error;

    allocator: std.mem.Allocator,
    file: std.fs.File,

    pub fn init(allocator: std.mem.Allocator, r: std.fs.File) NeedParsed {
        return NeedParsed{ .allocator = allocator, .file = r };
    }

    pub fn parse(self: NeedParsed, possibleLen: []const u8) Error!ParsedFile {
        const parsers = try self.allocator.alloc(ParserHeader, possibleLen.len);
        defer self.allocator.free(parsers);
        for (0.., possibleLen) |i, len| {
            parsers[i] = ParserHeader.init(self.allocator, len);
        }

        const r = self.file.reader();
        const buffer = try self.allocator.alloc(u8, 1024);
        defer self.allocator.free(buffer);
        while (true) {
            const n = try r.read(buffer);
            if (n == 0) {
                break;
            }

            for (parsers) |parser| {
                parser.load(buffer[0..n]);
            }
        }
        for (parsers) |parser| {
            parser.finish();
        }

        var less: usize = std.math.maxInt(usize);
        var lessParser: ParserHeader = undefined;
        for (parsers) |parser| {
            const len = parser.len();
            if (len < less) {
                less = len;
                lessParser = parser;
            }
        }

        const ret = ParsedFile.init(lessParser.header(), r);
        return ret;
    }
};

pub fn fileParse(allocator: std.mem.Allocator, r: std.fs.File) NeedParsed {
    return NeedParsed.init(allocator, r);
}
