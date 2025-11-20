// Entry point for a minimal Zig build system example.
// 程序入口点 用于 一个 最小化 Zig 构建 system 示例.
// This demonstrates the simplest possible Zig program structure that can be built
// 此 演示 simplest possible Zig program structure 该 can be built
// using the Zig build system, showing the basic main function and standard library import.
// 使用 Zig 构建 system, showing basic 主 函数 和 标准库 导入.
const std = @import("std");

pub fn main() !void {
    std.debug.print("Hello from minimal build!\n", .{});
}
