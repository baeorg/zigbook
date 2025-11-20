
// Import the standard library for core functionality
// 导入标准库 用于 core functionality
const std = @import("std");
// Import builtin to access compile-time target and optimization information
// 导入 内置 以访问 编译-time target 和 optimization 信息
const builtin = @import("builtin");

// / Demonstrates how to access and display build-time configuration information.
// / 演示 how 以访问 和 显示 构建-time configuration 信息.
// / This function prints the target architecture, OS, ABI, and optimization mode
// / 此 函数 prints target architecture, OS, ABI, 和 optimization 模式
// / that were configured during the build process.
// / 该 were configured during 构建 process.
pub fn main() !void {
    // Create a fixed-size buffer for stdout operations
    // 创建一个 固定大小缓冲区 用于 stdout operations
    var stdout_buffer: [256]u8 = undefined;
    // Initialize a buffered writer for stdout to improve performance
    // Initialize 一个 缓冲写入器 用于 stdout 到 improve performance
    var writer_state = std.fs.File.stdout().writer(&stdout_buffer);
    // Get the writer interface for output operations
    // 获取 writer 接口 用于 输出 operations
    const out = &writer_state.interface;

    // Print the target triple: CPU architecture, operating system, and ABI
    // 打印 target triple: CPU architecture, operating system, 和 ABI
    try out.print("target: {s}-{s}-{s}\n", .{
        @tagName(builtin.target.cpu.arch),
        @tagName(builtin.target.os.tag),
        @tagName(builtin.target.abi),
    });
    // Print the optimization mode (Debug, ReleaseSafe, ReleaseFast, or ReleaseSmall)
    // 打印 optimization 模式 (调试, ReleaseSafe, ReleaseFast, 或 ReleaseSmall)
    try out.print("optimize: {s}\n", .{@tagName(builtin.mode)});
    // Flush the buffer to ensure all output is written to stdout
    // 刷新 缓冲区 到 确保 所有 输出 is written 到 stdout
    try out.flush();
}
