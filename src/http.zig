const std = @import("std");

pub const Status = enum(u16) {
    ok = 200,
    not_found = 404,
    internet_server_error = 500,

    pub fn phrase(self: Status) []const u8 {
        return switch (self) {
            .ok => "OK",
            .not_found => "Not Found",
            .internet_server_error => "Internal Server Error",
        };
    }
};

pub const ContentType = enum {
    html,
    text,
    json,

    pub fn mime(self: ContentType) []const u8 {
        return switch (self) {
            .html => "text/html; charset=utf-8",
            .text => "text/plain; charset=utf-8",
            .json => "application/json; charset=UTF-8",
        };
    }
};

pub const Response = struct {
    status: Status = .ok,
    content_type: ContentType = .html,
    body: []const u8 = "",
};

fn sendAll(client: anytype, data: []const u8) !void {
    var sent: usize = 0;
    while (sent < data.len) {
        const n = try client.send(data[sent..], .{});
        if (n == 0) return error.ConnectionClosed;
        sent += n;
    }
}

pub fn respond(client: anytype, res: Response) !void {
    var head: [256]u8 = undefined;
    const header = try std.fmt.bufPrint(
        &head,
        "HTTP/1.1 {d} {s}\r\n" ++ "Content-Type: {s}\r\n" ++ "Content-Length: {d}\r\n" ++ "Connection: close\r\n" ++ "\r\n",
        .{ @backingInt(res.status), res.status.phrase(), res.content_type.mime(), res.body.len },
    );
    try sendAll(client, header);
    try sendAll(client, res.body);
}
