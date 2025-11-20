const std = @import("std");

// Demonstrates composing Reader -> Writer pipeline with delimiter streaming.
// 演示 composing Reader -> Writer pipeline 使用 delimiter streaming.
pub fn main() !void {
    const data = "alpha\nbeta\ngamma\n";
    var r: std.Io.Reader = .fixed(data);

    var out_buf: [128]u8 = undefined;
    var out: std.Io.Writer = .fixed(&out_buf);

    while (true) {
        // Stream one line (excluding the delimiter) then print processed form
        // Stream 一个 line (excluding delimiter) 那么 打印 processed form
        const line_opt = r.takeDelimiter('\n') catch |err| switch (err) {
            error.StreamTooLong => unreachable,
            error.ReadFailed => return err,
        };
        if (line_opt) |line| {
            try out.print("Line({d}): {s}\n", .{ line.len, line });
        } else break;
    }

    std.debug.print("{s}", .{out.buffered()});
}
