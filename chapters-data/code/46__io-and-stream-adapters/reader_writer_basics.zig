const std = @import("std");

// Demonstrates basic buffered writing using the new std.Io.Writer API
// 演示 basic 缓冲 writing 使用 新 std.Io.Writer API
// and then flushing to stdout via the older std.io File writer.
// 和 那么 flushing 到 stdout via older std.io 文件 writer.
pub fn main() !void {
    var buf: [128]u8 = undefined;
    // New streaming Writer backed by a fixed buffer. Writes accumulate until flushed/consumed.
    // 新 streaming Writer backed 通过 一个 fixed 缓冲区. Writes accumulate until flushed/consumed.
    var w: std.Io.Writer = .fixed(&buf);

    try w.print("Header: {s}\n", .{"I/O adapters"});
    try w.print("Value A: {d}\n", .{42});
    try w.print("Value B: {x}\n", .{0xdeadbeef});

    // Grab buffered bytes and print through std.debug (stdout)
    // Grab 缓冲 bytes 和 打印 through std.调试 (stdout)
    const buffered = w.buffered();
    std.debug.print("{s}", .{buffered});
}
