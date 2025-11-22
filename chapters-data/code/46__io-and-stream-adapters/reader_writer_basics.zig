const std = @import("std");

// 演示使用新的 std.Io.Writer API 进行基本的缓冲写入
// 然后通过旧的 std.io File 写入器刷新到标准输出。
pub fn main() !void {
    var buf: [128]u8 = undefined;
    // 由固定缓冲区支持的新流式写入器。写入会累积直到刷新/消费。
    var w: std.Io.Writer = .fixed(&buf);

    try w.print("Header: {s}\n", .{"I/O adapters"});
    try w.print("Value A: {d}\n", .{42});
    try w.print("Value B: {x}\n", .{0xdeadbeef});

    // 获取缓冲字节并通过 std.debug（标准输出）打印
    const buffered = w.buffered();
    std.debug.print("{s}", .{buffered});
}
