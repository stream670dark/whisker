# Whisker

> **Status:** early development. The API is unstable and will change.

## Requirements

- Zig 0.17.0 or newer
- Windows (other platforms are not supported yet)

## Installation

```sh 
zig fetch --save git+https://github.com/stream670dark/whisker 
```

Then, in your `build.zig`:

```zig
const whisker = b.dependency("whisker", .{
    .target = target,
    .optimize = optimize,
});
exe.root_module.addImport("whisker", whisker.module("whisker"));
```

## Usage

```zig
const wk = @import("whisker");

const page = @embedFile("index.html");

pub fn main() !void {
    var server = try wk.Server.listen(.{ .bind = "127.0.0.1", .port = 8080 });
    defer server.close();

    while (true) {
        var client = try server.accept();
        defer client.close();

        try wk.http.respond(&client, .{
            .content_type = .html,
            .body = page,
        });
    }
}
```