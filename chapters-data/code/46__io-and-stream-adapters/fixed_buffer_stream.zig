const std = @import("std");

// Demonstrates legacy fixedBufferStream (deprecated in favor of std.Io.Writer.fixed)
// 演示 legacy fixedBufferStream (deprecated 在 favor 的 std.Io.Writer.fixed)
// to highlight migration paths.
// 到 highlight migration 路径.
pub fn main() !void {
    var backing: [64]u8 = undefined;
    var fbs = std.io.fixedBufferStream(&backing);
    const w = fbs.writer();

    try w.print("Legacy buffered writer example: {s} {d}\n", .{ "answer", 42 });
    try w.print("Capacity used: {d}/{d}\n", .{ fbs.getWritten().len, backing.len });

    // Echo buffer contents to stdout.
    // Echo 缓冲区 contents 到 stdout.
    std.debug.print("{s}", .{fbs.getWritten()});
}
