const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    if (target.result.os.tag != .windows) @panic("Whisker only supports Windows for now");
    _ = b.addModule("whisker", .{
        .root_source_file = b.path("src/root.zig"),
    });
}
