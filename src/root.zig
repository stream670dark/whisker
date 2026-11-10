const std = @import("std");
const ws2 = @import("net/winsock2.zig");

pub const RecvFlags = ws2.Socket.RecvFlags;

pub const ListenOptions = struct {
    bind: ?[:0]const u8 = null,
    port: u16 = 0,
    backlog: u31 = 128,
};

pub const Server = struct {
    socket: ws2.Socket,
    port: u16,
    address: [4]u8,

    pub fn listen(options: ListenOptions) !Server {
        var wsa_data: ws2.WSAData = undefined;
        try wsa_data.startup(0x0202);
        errdefer ws2.WSAData.cleanup();

        var port_buf: [16]u8 = undefined;
        const port_str = try std.fmt.bufPrintSentinel(&port_buf, "{d}", .{options.port}, 0);

        const hints = ws2.AddrInfo{
            .flags = .{ .passive = true, .numerichost = false },
            .family = .inet,
            .socket_type = .stream,
            .protocol = .tcp,
        };

        const address = try ws2.AddrInfo.get(options.bind, port_str, &hints);
        defer address.free();

        var server_socket = try ws2.Socket.create(address);
        errdefer server_socket.close();

        try server_socket.bind(address);
        try server_socket.listen(options.backlog);

        const sockaddr: *const ws2.SockAddrIn = @ptrCast(@alignCast(address.addr.?));
        const ip_bytes: *const [4]u8 = @ptrCast(&sockaddr.addr);

        return Server{
            .socket = server_socket,
            .port = options.port,
            .address = ip_bytes.*,
        };
    }

    pub fn accept(self: *Server) ws2.Socket.AcceptError!ws2.Socket {
        return self.socket.accept();
    }

    pub fn close(self: *Server) void {
        self.socket.close();
        ws2.WSAData.cleanup();
    }
};
