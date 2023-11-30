const std = @import("std");

pub const ParsedHeader = struct {
    size: u8,
    map: []typeMap,
    len: u64 = 123,

    pub fn init(ph: *const ParserHeader) ParsedHeader {
        return ParsedHeader{
            .size = ph.size,
            .map = ph.map,
        };
    }
};

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

// TODO self dynamic type
const typeMap = u32;

pub const ParserHeader = struct {
    parsedHeader: ?ParsedHeader = null,
    allocator: std.mem.Allocator,
    n: u64 = 0,
    used_len: u8 = 0,
    size: u8,
    map: []typeMap,

    pub fn init(allocator: std.mem.Allocator, size: u8) std.mem.Allocator.Error!ParserHeader {
        const d = try allocator.alloc(typeMap, @as(usize, 1) << @intCast(size));
        for (d) |*i| {
            i.* = 0;
        }

        return ParserHeader{ .allocator = allocator, .size = size, .map = d };
    }

    pub fn deinit(self: *const ParserHeader) void {
        self.allocator.free(self.map);
    }

    pub fn load(ph: *ParserHeader, buffer: []const u8) void {
        ph.parsedHeader = null;
        for (buffer) |b| {
            ph.n = ph.n << 8 | @as(u64, b);
            ph.used_len += 8;
            while (ph.used_len >= ph.size) {
                const ll: u6 = @intCast(ph.used_len - ph.size);
                const index = @as(usize, ph.n >> ll);
                ph.map[index] += 1;
                ph.n &= (@as(u64, 1) << ll) - 1;
                ph.used_len -= ph.size;
            }
        }
    }

    pub fn finish(ph: *ParserHeader) void {
        ph.calcHeader();
    }

    pub fn len(self: *ParserHeader) u64 {
        return self.getParsed().len;
    }

    pub fn getParsed(self: *ParserHeader) ParsedHeader {
        if (self.parsedHeader == null) self.calcHeader();
        return self.parsedHeader.?;
    }

    fn calcHeader(ph: *ParserHeader) void {
        ph.parsedHeader = ParsedHeader.init(ph);
    }
};

pub const NeedParsed = struct {
    const Error = std.mem.Allocator.Error || std.fs.File.Reader.Error || std.fs.File.SeekError;

    allocator: std.mem.Allocator,
    file: std.fs.File,

    pub fn init(allocator: std.mem.Allocator, r: std.fs.File) NeedParsed {
        return NeedParsed{ .allocator = allocator, .file = r };
    }

    pub fn parse(self: NeedParsed, possibleLen: []const u8) Error!ParsedFile {
        const parsers = try self.allocator.alloc(ParserHeader, possibleLen.len);
        defer {
            for (parsers) |parser| {
                parser.deinit();
            }
            self.allocator.free(parsers);
        }
        for (0.., possibleLen) |i, len| {
            parsers[i] = try ParserHeader.init(self.allocator, len);
        }

        const r = self.file.reader();
        const buffer = try self.allocator.alloc(u8, 1024);
        defer self.allocator.free(buffer);
        while (true) {
            const n = try r.read(buffer);
            if (n == 0) {
                break;
            }

            for (parsers) |*parser| {
                parser.load(buffer[0..n]);
            }
        }

        for (parsers) |*parser| {
            parser.finish();
        }

        // std.time.sleep(1e10);

        var less: u64 = std.math.maxInt(usize);
        var lessParser: *ParserHeader = undefined;
        for (parsers) |*parser| {
            const len = parser.len();
            // std.debug.print("len: {}, size: {}\n", .{ len, parser.size });
            if (len < less) {
                less = len;
                lessParser = parser;
            }
        }

        try self.file.seekTo(0);
        const ret = ParsedFile.init(lessParser.getParsed(), r);
        return ret;
    }
};

pub fn fileParse(allocator: std.mem.Allocator, r: std.fs.File) NeedParsed {
    return NeedParsed.init(allocator, r);
}
