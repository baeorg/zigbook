const std = @import("std");

// 演示使用分隔符流将 Reader -> Writer 管道组合。
pub fn main() !void {
    const data = "alpha\nbeta\ngamma\n";
    var r: std.Io.Reader = .fixed(data);

    var out_buf: [128]u8 = undefined;
    var out: std.Io.Writer = .fixed(&out_buf);

    while (true) {
        // 流式传输一行（不包括分隔符），然后打印处理后的形式
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
