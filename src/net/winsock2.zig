const std = @import("std");

pub const WSADESCRIPTION_LEN = 256;
pub const WSASYS_STATUS_LEN = 128;

pub const INVALID_SOCKET = ~@as(usize, 0);
pub const SOCKET_ERROR = @as(isize, -1);

pub const AddressFamily = enum(i32) {
    unspec = 0,
    inet = 2,
    inet6 = 23,
};
pub const SocketType = enum(i32) {
    unspec = 0,
    stream = 1,
    dgram = 2,
    raw = 3,
};
pub const IPProtocol = enum(i32) {
    ip = 0,
    tcp = 6,
    udp = 17,
};
pub const AddrInfoFlags = packed struct(i32) {
    passive: bool = false,
    canonname: bool = false,
    numerichost: bool = false,
    _padding: u29 = 0,
};

const WSASYSNOTREADY: i32 = 10091;
const WSAVERNOTSUPPORTED: i32 = 10092;
const WSAEFAULT: i32 = 10014;
const WSAEINPROGRESS: i32 = 10036;
const WSAEPROCLIM: i32 = 10067;
const WSATRY_AGAIN: i32 = 10004;
const WSAEINVAL: i32 = 10022;
const WSAETIMEDOUT: i32 = 10060;
const WSAEAFNOSUPPORT: i32 = 10047;
const WSAENOBUFS: i32 = 10055;
const WSANOTINITIALISED: i32 = 10093;
const WSAHOST_NOT_FOUND: i32 = 11001;
const WSAESOCKTNOSUPPORT: i32 = 10044;
const WSAEPROTONOSUPPORT: i32 = 10043;
const WSAEACCES: i32 = 10013;
const WSAEADDRINUSE: i32 = 10048;
const WSAEADDRNOTAVAIL: i32 = 10049;
const WSAENOTSOCK: i32 = 10038;
const WSAEISCONN: i32 = 10056;
const WSAEOPNOTSUPP: i32 = 10045;
const WSAECONNRESET: i32 = 10054;
const WSAEINTR: i32 = 10004;
const WSAEMFILE: i32 = 10024;
const WSAENETDOWN: i32 = 10050;
const WSAENOTCONN: i32 = 10057;
const WSAENETRESET: i32 = 10052;
const WSAESHUTDOWN: i32 = 10058;
const WSAEWOULDBLOCK: i32 = 10035;
const WSAEMSGSIZE: i32 = 10040;
const WSAECONNABORTED: i32 = 10053;

pub const SockAddrIn = extern struct {
    family: i16,
    port: u16,
    addr: u32,
    zero: [8]u8,
};

const c = struct {
    extern "ws2_32" fn getaddrinfo(pNodeName: ?[*:0]const u8, pServiceName: ?[*:0]const u8, pHints: ?*const AddrInfo, ppResult: *?*AddrInfo) callconv(.winapi) i32;
    extern "ws2_32" fn freeaddrinfo(pAddrInfo: *AddrInfo) callconv(.winapi) void;
    extern "ws2_32" fn WSAStartup(wVersionRequired: u16, lpWSAData: *WSAData) callconv(.winapi) i32;
    extern "ws2_32" fn WSACleanup() callconv(.winapi) i32;
    extern "ws2_32" fn WSAGetLastError() i32;
    extern "ws2_32" fn socket(af: i32, type: i32, protocol: i32) callconv(.winapi) usize;
    extern "ws2_32" fn closesocket(s: usize) callconv(.winapi) i32;
    extern "ws2_32" fn bind(s: usize, addr: ?*anyopaque, namelen: i32) callconv(.winapi) i32;
    extern "ws2_32" fn listen(s: usize, backlog: i32) callconv(.winapi) i32;
    extern "ws2_32" fn accept(s: usize, addr: ?*anyopaque, addrlen: ?*i32) callconv(.winapi) usize;
    extern "ws2_32" fn recv(s: usize, buf: [*]u8, len: i32, flags: i32) callconv(.winapi) i32;
    extern "ws2_32" fn send(s: usize, buf: [*]const u8, len: i32, flags: i32) callconv(.winapi) i32;
};

pub const AddrInfo = extern struct {
    flags: AddrInfoFlags = .{},
    family: AddressFamily = .unspec,
    socket_type: SocketType = .unspec,
    protocol: IPProtocol = .ip,
    addrlen: usize = 0,
    canonname: ?[*:0]u8 = null,
    addr: ?*anyopaque = null,
    next: ?*@This() = null,

    pub const Error = error{
        AddressFamilyNotSupported,
        TemporaryFailure,
        BadFlags,
        NonRecoverableFailure,
        FamilyNotSupported,
        MemoryAllocationFailed,
        NoAddress,
        ServiceNotSupported,
        SocketTypeNotSupported,
        UnknownError,
    };

    pub fn get(node_name: [*:0]const u8, service_name: ?[*:0]const u8, hints: ?*const @This()) Error!*@This() {
        var result: ?*@This() = null;
        const err_code = c.getaddrinfo(node_name, service_name, hints, &result);
        return switch (err_code) {
            0 => result.?,
            WSATRY_AGAIN => error.TemporaryFailure,
            WSAEINVAL => error.BadFlags,
            WSAETIMEDOUT => error.NonRecoverableFailure,
            WSAEAFNOSUPPORT => error.FamilyNotSupported,
            WSAENOBUFS => error.MemoryAllocationFailed,
            WSANOTINITIALISED => error.UnknownError,
            WSAHOST_NOT_FOUND => error.NoAddress,
            WSAESOCKTNOSUPPORT => error.SocketTypeNotSupported,
            WSAEPROTONOSUPPORT => error.ServiceNotSupported,
            else => error.UnknownError,
        };
    }

    pub fn free(self: *@This()) void {
        c.freeaddrinfo(self);
    }
};

pub const WSAData = extern struct {
    wVersion: u16,
    wHighVersion: u16,
    iMaxSockets: u16,
    iMaxUdpDg: u16,
    lpVendorInfo: ?[*]u8,
    szDescription: [WSADESCRIPTION_LEN + 1]u8,
    szSystemStatus: [WSASYS_STATUS_LEN + 1]u8,

    pub const Error = error{
        SystemNotReady,
        VersionNotSupported,
        BadAddress,
        OperationInProgress,
        TooManyProcesses,
        UnknownError,
    };

    pub fn startup(self: *@This(), version: u16) Error!void {
        const result = c.WSAStartup(version, self);
        return switch (result) {
            0 => {},
            WSASYSNOTREADY => error.SystemNotReady,
            WSAVERNOTSUPPORTED => error.VersionNotSupported,
            WSAEFAULT => error.BadAddress,
            WSAEINPROGRESS => error.OperationInProgress,
            WSAEPROCLIM => error.TooManyProcesses,
            else => error.UnknownError,
        };
    }

    pub fn cleanup() void {
        _ = c.WSACleanup();
    }
};

pub const Socket = struct {
    descriptor: usize,

    pub fn create(info: *const AddrInfo) !Socket {
        const socket = c.socket(
            @as(i32, @intCast(@backingInt(info.family))),
            @as(i32, @intCast(@backingInt(info.socket_type))),
            @as(i32, @intCast(@backingInt(info.protocol))),
        );

        if (socket == INVALID_SOCKET) {
            return error.SocketCreationFailed;
        }

        return Socket{
            .descriptor = socket,
        };
    }

    pub fn close(self: *@This()) void {
        _ = c.closesocket(self.descriptor);
    }

    pub const BindError = error{
        AccessDenied,
        AddressInUse,
        AddressNotAvailable,
        NotASocket,
        UnknownError,
    };

    pub fn bind(self: *const @This(), info: *const AddrInfo) BindError!void {
        const result = c.bind(self.descriptor, info.addr, @as(i32, @intCast(info.addrlen)));
        if (result == SOCKET_ERROR) {
            const err_code = c.WSAGetLastError();
            return switch (err_code) {
                WSAEACCES => error.AccessDenied,
                WSAEADDRINUSE => error.AddressInUse,
                WSAEADDRNOTAVAIL => error.AddressNotAvailable,
                WSAENOTSOCK => error.NotASocket,
                else => error.UnknownError,
            };
        }
    }

    pub const ListenError = error{
        NotASocket,
        AlreadyConnected,
        OperationNotSupported,
        NotBound,
        UnknownError,
    };

    pub fn listen(self: *const @This(), backlog: i32) ListenError!void {
        const result = c.listen(self.descriptor, backlog);

        if (result == SOCKET_ERROR) {
            const err_code = c.WSAGetLastError();

            return switch (err_code) {
                WSAENOTSOCK => error.NotASocket,
                WSAEISCONN => error.AlreadyConnected,
                WSAEOPNOTSUPP => error.OperationNotSupported,
                WSAEINVAL => error.NotBound,
                else => error.UnknownError,
            };
        }
    }

    pub const AcceptError = error{
        NotASocket,
        ConnectionReset,
        Interrupted,
        NotListening,
        NoMoreSockets,
        UnknownError,
    };

    pub fn accept(self: *@This()) AcceptError!Socket {
        const new_socket = c.accept(self.descriptor, null, null);

        if (new_socket == INVALID_SOCKET) {
            const err_code = c.WSAGetLastError();
            return switch (err_code) {
                WSAENOTSOCK => error.NotASocket,
                WSAECONNRESET => error.ConnectionReset,
                WSAEINTR => error.Interrupted,
                WSAEINVAL => error.NotListening,
                WSAEMFILE => error.NoMoreSockets,
                else => error.UnknownError,
            };
        }

        return Socket{ .descriptor = new_socket };
    }

    pub const RecvFlags = packed struct(i32) {
        oob: bool = false,
        peek: bool = false,
        dontroute: bool = false,
        waitall: bool = false,
        _padding: u28 = 0,
    };

    pub const RecvError = error{
        NotInitialised,
        NetworkDown,
        BadAddress,
        NotConnected,
        Interrupted,
        InProgress,
        NetworkReset,
        NotASocket,
        OperationNotSupported,
        SocketShutdown,
        WouldBlock,
        MessageTooLarge,
        InvalidArguments,
        ConnectionAborted,
        ConnectionTimedOut,
        ConnectionReset,
        UnknownError,
    };

    pub fn recv(self: *const @This(), buffer: []u8, flags: RecvFlags) RecvError!usize {
        const result = c.recv(self.descriptor, buffer.ptr, @as(i32, @intCast(buffer.len)), @as(i32, @bitCast(flags)));

        if (result == SOCKET_ERROR) {
            const err_code = c.WSAGetLastError();
            return switch (err_code) {
                WSANOTINITIALISED => error.NotInitialised,
                WSAENETDOWN => error.NetworkDown,
                WSAEFAULT => error.BadAddress,
                WSAENOTCONN => error.NotConnected,
                WSAEINTR => error.Interrupted,
                WSAEINPROGRESS => error.InProgress,
                WSAENETRESET => error.NetworkReset,
                WSAENOTSOCK => error.NotASocket,
                WSAEOPNOTSUPP => error.OperationNotSupported,
                WSAESHUTDOWN => error.SocketShutdown,
                WSAEWOULDBLOCK => error.WouldBlock,
                WSAEMSGSIZE => error.MessageTooLarge,
                WSAEINVAL => error.InvalidArguments,
                WSAECONNABORTED => error.ConnectionAborted,
                WSAETIMEDOUT => error.ConnectionTimedOut,
                WSAECONNRESET => error.ConnectionReset,
                else => error.UnknownError,
            };
        }

        return @as(usize, @intCast(result));
    }

    pub const SendFlags = packed struct(i32) {
        oob: bool = false,
        dontroute: bool = false,
        _padding: u30 = 0,
    };

    pub const SendError = error{
        NotInitialised,
        NetworkDown,
        BadAddress,
        NotConnected,
        Interrupted,
        InProgress,
        NetworkReset,
        NotASocket,
        OperationNotSupported,
        SocketShutdown,
        WouldBlock,
        MessageTooLarge,
        InvalidArguments,
        ConnectionAborted,
        ConnectionTimedOut,
        ConnectionReset,
        UnknownError,
    };

    pub fn send(self: *const @This(), buffer: []const u8, flags: SendFlags) SendError!usize {
        const result = c.send(self.descriptor, buffer.ptr, @as(i32, @intCast(buffer.len)), @as(i32, @bitCast(flags)));

        if (result == SOCKET_ERROR) {
            const err_code = c.WSAGetLastError();
            return switch (err_code) {
                WSANOTINITIALISED => error.NotInitialised,
                WSAENETDOWN => error.NetworkDown,
                WSAEFAULT => error.BadAddress,
                WSAENOTCONN => error.NotConnected,
                WSAEINTR => error.Interrupted,
                WSAEINPROGRESS => error.InProgress,
                WSAENETRESET => error.NetworkReset,
                WSAENOTSOCK => error.NotASocket,
                WSAEOPNOTSUPP => error.OperationNotSupported,
                WSAESHUTDOWN => error.SocketShutdown,
                WSAEWOULDBLOCK => error.WouldBlock,
                WSAEMSGSIZE => error.MessageTooLarge,
                WSAEINVAL => error.InvalidArguments,
                WSAECONNABORTED => error.ConnectionAborted,
                WSAETIMEDOUT => error.ConnectionTimedOut,
                WSAECONNRESET => error.ConnectionReset,
                else => error.UnknownError,
            };
        }

        return @as(usize, @intCast(result));
    }
};
