const std = @import("std");

// 使用 Writer.fixed 和缓冲长度的简单计数示例。
pub fn main() !void {
    var buf: [128]u8 = undefined;
    var w: std.Io.Writer = .fixed(&buf);
    try w.print("Counting: {s} {d}\n", .{ "bytes", 123 });
    try w.print("And more\n", .{});
    const written = w.buffered().len;
    std.debug.print("Total bytes logically written: {d}\n", .{written});
}
