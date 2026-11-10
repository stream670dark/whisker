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
        var client = server.accept() catch continue;
        defer client.close();

        wk.http.respond(&client, .{
            .content_type = .html,
            .body = page,
        }) catch {};
    }
}
```

By default the server listens on `127.0.0.1`, so it is only reachable from
your own machine. To accept connections from the network, bind explicitly:

```zig
var server = try wk.Server.listen(.{ .bind = "0.0.0.0", .port = 8080 });
```

`bind` expects an IP address, not a hostname.

## License

See [LICENSE](LICENSE).