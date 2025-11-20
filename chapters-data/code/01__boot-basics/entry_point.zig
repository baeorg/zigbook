// File: chapters-data/code/01__boot-basics/entry_point.zig

// Import the standard library for I/O and utility functions
// 导入标准库以使用I/O及工具函数
const std = @import("std");
// Import builtin to access compile-time information like build mode
// 导入内置模块以访问编译时信息（例如构建模式）
const builtin = @import("builtin");

// Define a custom error type for build mode violations
// 定义用于表示构建模式违规的自定义错误类型
const ModeError = error{ReleaseOnly};

// Main entry point of the program
// 程序的主入口点
// Returns an error union to propagate any errors that occur during execution
// 返回错误联合类型以传播执行过程中产生的所有错误
pub fn main() !void {
    // Attempt to enforce debug mode requirement
    // 尝试强制执行调试模式要求
    // If it fails, catch the error and print a warning instead of terminating
    // 失败时捕获错误并打印警告，而非终止程序
    requireDebugSafety() catch |err| {
        std.debug.print("warning: {s}\n", .{@errorName(err)});
    };

    // Print startup message to stdout
    // 打印启动消息到标准输出
    try announceStartup();
}

// Validates that the program is running in Debug mode
// 验证程序是否在调试模式下运行
// Returns an error if compiled in Release mode to demonstrate error handling
// 如果以发布模式编译则返回错误（用于演示错误处理）
fn requireDebugSafety() ModeError!void {
    // Check compile-time build mode
    // 检查编译时的构建模式
    if (builtin.mode == .Debug) return;
    // Return error if not in Debug mode
    // 如果不在调试模式下则返回错误
    return ModeError.ReleaseOnly;
}

// Writes a startup announcement message to standard output
// 向标准输出写入启动公告消息
// Demonstrates buffered I/O operations in Zig
// 演示Zig中的缓冲I/O操作
fn announceStartup() !void {
    // Allocate a fixed-size buffer on the stack for stdout operations
    // 在栈上分配固定大小的缓冲区用于标准输出操作
    var stdout_buffer: [128]u8 = undefined;
    // Create a buffered writer wrapping stdout
    // 创建包装标准输出的缓冲写入器
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    // Get the generic writer interface for polymorphic I/O
    // 获取用于多态I/O的通用写入器接口
    const stdout = &stdout_writer.interface;
    // Write formatted message to the buffer
    // 向缓冲区写入格式化消息
    try stdout.print("Zig entry point reporting in.\n", .{});
    // Flush the buffer to ensure message is written to stdout
    // 刷新缓冲区以确保消息写入标准输出
    try stdout.flush();
}
