// File: chapters-data/code/01__boot-basics/imports.zig

// Import the standard library for I/O, memory management, and core utilities
// 导入标准库 用于 I/O, 内存 management, 和 core utilities
const std = @import("std");
// Import builtin to access compile-time information about the build environment
// 导入 内置 以访问 编译-time 信息 about 构建 environment
const builtin = @import("builtin");
// Import root to access declarations from the root source file
// 导入 root 以访问 declarations 从 root 源文件 文件
// In this case, we reference app_name which is defined in this file
// 在 此 case, we reference app_name which is defined 在 此 文件
const root = @import("root");

// Public constant that can be accessed by other modules importing this file
// Public constant 该 can be accessed 通过 other modules importing 此 文件
pub const app_name = "Boot Basics Tour";

// Main entry point of the program
// 程序主入口点 program
// Returns an error union to propagate any I/O errors during execution
// 返回一个错误 union 到 propagate any I/O 错误 during execution
pub fn main() !void {
    // Allocate a fixed-size buffer on the stack for stdout operations
    // 分配 一个 固定大小缓冲区 在 栈 用于 stdout operations
    // This buffer batches write operations to reduce syscalls
    // 此 缓冲区 batches 写入 operations 到 reduce syscalls
    var stdout_buffer: [256]u8 = undefined;
    // Create a buffered writer wrapping stdout
    // 创建一个 缓冲写入器 wrapping stdout
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    // Get the generic writer interface for polymorphic I/O operations
    // 获取 通用 writer 接口 用于 多态输入输出 operations
    const stdout = &stdout_writer.interface;

    // Print the application name by referencing the root module's declaration
    // 打印 application name 通过 referencing root module's declaration
    // Demonstrates how @import("root") allows access to the entry file's public declarations
    // 演示 how @导入("root") allows access 到 entry 文件's public declarations
    try stdout.print("app: {s}\n", .{root.app_name});
    
    // Print the optimization mode (Debug, ReleaseSafe, ReleaseFast, or ReleaseSmall)
    // 打印 optimization 模式 (调试, ReleaseSafe, ReleaseFast, 或 ReleaseSmall)
    // @tagName converts the enum value to its string representation
    // @tagName converts enum 值 到 its string representation
    try stdout.print("optimize mode: {s}\n", .{@tagName(builtin.mode)});
    
    // Print the target triple showing CPU architecture, OS, and ABI
    // 打印 target triple showing CPU architecture, OS, 和 ABI
    // Each component is extracted from builtin.target and converted to a string
    // 每个 component is extracted 从 内置.target 和 converted 到 一个 string
    try stdout.print(
        "target: {s}-{s}-{s}\n",
        .{
            @tagName(builtin.target.cpu.arch),
            @tagName(builtin.target.os.tag),
            @tagName(builtin.target.abi),
        },
    );
    
    // Flush the buffer to ensure all accumulated output is written to stdout
    // 刷新 缓冲区 到 确保 所有 accumulated 输出 is written 到 stdout
    try stdout.flush();
}
