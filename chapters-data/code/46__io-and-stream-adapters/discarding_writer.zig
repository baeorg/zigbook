const std = @import("std");

// 演示 std.Io.Writer.Discarding 以忽略输出（在基准测试中很有用）
pub fn main() !void {
    var buf: [32]u8 = undefined;
    var w: std.Io.Writer = .fixed(&buf);

    try w.print("Ephemeral output: {d}\n", .{999});

    // 通过消费缓冲字节来丢弃内容
    _ = std.Io.Writer.consumeAll(&w);

    // 显示缓冲区现在为空
    std.debug.print("Buffer after consumeAll length: {d}\n", .{w.buffered().len});
}
