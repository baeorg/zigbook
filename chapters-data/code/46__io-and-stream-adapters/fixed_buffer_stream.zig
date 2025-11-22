const std = @import("std");

// 演示传统 fixedBufferStream（已弃用，推荐使用 std.Io.Writer.fixed）
// 以突出迁移路径。
pub fn main() !void {
    var backing: [64]u8 = undefined;
    var fbs = std.io.fixedBufferStream(&backing);
    const w = fbs.writer();

    try w.print("Legacy buffered writer example: {s} {d}\n", .{ "answer", 42 });
    try w.print("Capacity used: {d}/{d}\n", .{ fbs.getWritten().len, backing.len });

    // Echo buffer contents to stdout.
    // 回显缓冲区内容到stdout。
    std.debug.print("{s}", .{fbs.getWritten()});
}
