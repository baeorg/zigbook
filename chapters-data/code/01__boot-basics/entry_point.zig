// File: chapters-data/code/01__boot-basics/entry_point.zig

// Import the standard library for I/O and utility functions
// 导入标准库 用于 I/O 和 工具函数 函数
const std = @import("std");
// Import builtin to access compile-time information like build mode
// 导入 内置 以访问 编译-time 信息 如构建模式
const builtin = @import("builtin");

// Define a custom error type for build mode violations
// 定义自定义错误 类型 用于 构建模式 violations
const ModeError = error{ReleaseOnly};

// Main entry point of the program
// 程序主入口点 program
// Returns an error union to propagate any errors that occur during execution
// 返回一个错误 union 到 propagate any 错误 该 occur during execution
pub fn main() !void {
    // Attempt to enforce debug mode requirement
    // 尝试 enforce 调试模式 requirement
    // If it fails, catch the error and print a warning instead of terminating
    // 如果 it fails, 捕获 错误 和 打印 一个 warning 而非 terminating
    requireDebugSafety() catch |err| {
        std.debug.print("warning: {s}\n", .{@errorName(err)});
    };

    // Print startup message to stdout
    // 打印启动 message 到 stdout
    try announceStartup();
}

// Validates that the program is running in Debug mode
// 验证 program is running 在 调试模式
// Returns an error if compiled in Release mode to demonstrate error handling
// 返回一个错误 如果 compiled 在 发布模式 到 demonstrate 错误处理
fn requireDebugSafety() ModeError!void {
    // Check compile-time build mode
    // 检查 编译-time 构建模式
    if (builtin.mode == .Debug) return;
    // Return error if not in Debug mode
    // 返回 错误 如果 不 在 调试模式
    return ModeError.ReleaseOnly;
}

// Writes a startup announcement message to standard output
// Writes 一个 startup announcement message 到 标准输出
// Demonstrates buffered I/O operations in Zig
// 演示 缓冲 I/O operations 在 Zig
fn announceStartup() !void {
    // Allocate a fixed-size buffer on the stack for stdout operations
    // 分配 一个 固定大小缓冲区 在 栈 用于 stdout operations
    var stdout_buffer: [128]u8 = undefined;
    // Create a buffered writer wrapping stdout
    // 创建一个 缓冲写入器 wrapping stdout
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    // Get the generic writer interface for polymorphic I/O
    // 获取 通用 writer 接口 用于 多态输入输出
    const stdout = &stdout_writer.interface;
    // Write formatted message to the buffer
    // 写入 格式化消息 到 缓冲区
    try stdout.print("Zig entry point reporting in.\n", .{});
    // Flush the buffer to ensure message is written to stdout
    // 刷新 缓冲区 到 确保 message is written 到 stdout
    try stdout.flush();
}
