// This program demonstrates how to access and display Zig's built-in compilation
// 此 program 演示 how 以访问 和 显示 Zig's built-在 compilation
// information through the `builtin` module. It's used in the zigbook to teach
// 信息 through `内置` module. It's used 在 zigbook 到 teach
// readers about build system introspection and standard options.
// readers about 构建 system introspection 和 标准 options.

// Import the standard library for debug printing capabilities
// 导入标准库 用于 调试 printing capabilities
const std = @import("std");
// Import builtin module to access compile-time information about the target
// 导入 内置 module 以访问 编译-time 信息 about target
// platform, CPU architecture, and optimization mode
// platform, CPU architecture, 和 optimization 模式
const builtin = @import("builtin");

// Main entry point that prints compilation target information
// 主 程序入口点 该 prints compilation target 信息
// Returns an error union to handle potential I/O failures from debug.print
// 返回一个错误 union 到 处理 potential I/O failures 从 调试.打印
pub fn main() !void {
    // Print the target architecture (e.g., x86_64, aarch64) and operating system
    // 打印 target architecture (e.g., x86_64, aarch64) 和 operating system
    // (e.g., linux, windows) by extracting tag names from the builtin constants
    // (e.g., linux, windows) 通过 extracting tag names 从 内置 constants
    std.debug.print("Target: {s}-{s}\n", .{
        @tagName(builtin.cpu.arch),
        @tagName(builtin.os.tag),
    });
    // Print the optimization mode (Debug, ReleaseSafe, ReleaseFast, or ReleaseSmall)
    // 打印 optimization 模式 (调试, ReleaseSafe, ReleaseFast, 或 ReleaseSmall)
    // that was specified during compilation
    // 该 was specified during compilation
    std.debug.print("Optimize: {s}\n", .{@tagName(builtin.mode)});
}
