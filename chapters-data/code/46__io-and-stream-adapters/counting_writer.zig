const std = @import("std");

// Simple counting example using Writer.fixed and buffered length.
// Simple counting 示例 使用 Writer.fixed 和 缓冲 length.
pub fn main() !void {
    var buf: [128]u8 = undefined;
    var w: std.Io.Writer = .fixed(&buf);
    try w.print("Counting: {s} {d}\n", .{"bytes", 123});
    try w.print("And more\n", .{});
    const written = w.buffered().len;
    std.debug.print("Total bytes logically written: {d}\n", .{written});
}
