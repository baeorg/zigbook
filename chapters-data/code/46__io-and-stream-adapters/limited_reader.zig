const std = @import("std");

// 使用 std.Io.Reader.Limited 从输入中最多读取 N 个字节
pub fn main() !void {
    const input = "Hello, world!\nRest is skipped";
    var r: std.Io.Reader = .fixed(input);

    var tmp: [8]u8 = undefined; // 限制读取器背后的缓冲区
    var limited = r.limited(.limited(5), &tmp); // 只允许前 5 个字节

    var out_buf: [64]u8 = undefined;
    var out: std.Io.Writer = .fixed(&out_buf);

    // 泵送直到限制触发限制读取器的 EndOfStream
    _ = limited.interface.streamRemaining(&out) catch |err| {
        switch (err) {
            error.WriteFailed, error.ReadFailed => unreachable,
        }
    };

    std.debug.print("{s}\n", .{out.buffered()});
}
