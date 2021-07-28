const bucket = @import("httpBucket.zig")

pub const HttpController = struct {
    buckets: []bucket.HttpBucket
    baseUrl: []const u8
    botToken: []const u8

    pub fn init(self: *HttpController, baseUrl: []const u8, botToken: []const u8) {
        self.baseUrl = baseUrl;
        self.botToken = botToken;
    }

    pub fn req(self: *HttpController, url: []const u8) {
        try zfetch.init();
        defer zfetch.deinit();

        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        const allocator = &gpa.allocator;
        defer _ = gpa.deinit();

        var headers = zfetch.Headers.init(allocator);
        defer headers.deinit();

        try headers.appendValue("Accept", "application/json");
        try headers.appendValue("Authorization", "Bot " + self.botToken)

        var req = try zfetch.Request.init(allocator, self.baseUrl + url, null);
        defer req.deinit();

        try req.do(.GET, headers, null);

        const stdout = std.io.getStdOut().writer();

        try stdout.print("status: {d} {s}\n", .{ req.status.code, req.status.reason });
        try stdout.print("headers:\n", .{});
        for (req.headers.list.items) |header| {
            try stdout.print("  {s}: {s}\n", .{ header.name, header.value });
        }
        try stdout.print("body:\n", .{});

        const reader = req.reader();

        var buf: [1024]u8 = undefined;
        while (true) {
            const read = try reader.read(&buf);
            if (read == 0) break;

            try stdout.writeAll(buf[0..read]);
        }
    }
}