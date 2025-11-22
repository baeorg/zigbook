// Import the standard library for core functionality
// 导入标准库以获取核心功能
const std = @import("std");
// Import builtin to access compile-time target and optimization information
// 导入内置模块以访问编译时目标和优化信息
const builtin = @import("builtin");

// / Demonstrates how to access and display build-time configuration information.
// / 演示如何访问和显示构建时配置信息。
// / This function prints the target architecture, OS, ABI, and optimization mode
// / 此函数打印在构建过程中配置的目标架构、操作系统、ABI 和优化模式。
pub fn main() !void {
    // Create a fixed-size buffer for stdout operations
    // 为标准输出操作创建一个固定大小的缓冲区
    var stdout_buffer: [256]u8 = undefined;
    // Initialize a buffered writer for stdout to improve performance
    // 初始化一个缓冲写入器以提高标准输出性能
    var writer_state = std.fs.File.stdout().writer(&stdout_buffer);
    // Get the writer interface for output operations
    // 获取用于输出操作的写入器接口
    const out = &writer_state.interface;

    // Print the target triple: CPU architecture, operating system, and ABI
    // 打印目标三元组：CPU架构、操作系统和ABI
    try out.print("target: {s}-{s}-{s}\n", .{
        @tagName(builtin.target.cpu.arch),
        @tagName(builtin.target.os.tag),
        @tagName(builtin.target.abi),
    });
    // Print the optimization mode (Debug, ReleaseSafe, ReleaseFast, or ReleaseSmall)
    // 打印优化模式（Debug、ReleaseSafe、ReleaseFast 或 ReleaseSmall）
    try out.print("optimize: {s}\n", .{@tagName(builtin.mode)});
    // Flush the buffer to ensure all output is written to stdout
    // 刷新缓冲区以确保所有输出写入标准输出
    try out.flush();
}
