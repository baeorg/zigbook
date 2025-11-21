const std = @import("std");

test "no leak when freeing properly" {
    // 使用测试分配器，它跟踪分配并检测泄漏
    const allocator = std.testing.allocator;

    // 在堆上分配64字节缓冲区
    const buf = try allocator.alloc(u8, 64);
    // 安排在作用域退出时释放（确保清理）
    defer allocator.free(buf);

    // 用0xAA模式填充缓冲区以演示用法
    for (buf) |*b| b.* = 0xAA;

    // 当测试退出时，defer运行allocator.free(buf)
    // 测试分配器验证所有分配都被释放
}
