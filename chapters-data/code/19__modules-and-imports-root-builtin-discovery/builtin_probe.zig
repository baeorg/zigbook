// Import the standard library for I/O and basic functionality
// 导入标准库 用于 I/O 和 basic functionality
const std = @import("std");
// Import the builtin module to access compile-time build information
// 导入 内置 module 以访问 编译-time 构建 信息
const builtin = @import("builtin");

// Compute a human-readable hint about the current optimization mode at compile time.
// Compute 一个 human-readable hint about 当前 optimization 模式 在 编译时.
// This block evaluates once during compilation and embeds the result as a constant string.
// 此 block evaluates once during compilation 和 embeds result 作为 一个 constant string.
const optimize_hint = blk: {
    break :blk switch (builtin.mode) {
        .Debug => "debug symbols and runtime safety checks enabled",
        .ReleaseSafe => "runtime checks on, optimized for safety",
        .ReleaseFast => "optimizations prioritized for speed",
        .ReleaseSmall => "optimizations prioritized for size",
    };
};

// / Entry point for the builtin probe utility.
// / 程序入口点 用于 内置 probe 工具函数.
// / Demonstrates how to query and display compile-time build configuration
// / 演示 how 到 query 和 显示 编译-time 构建 configuration
// / from the `builtin` module, including Zig version, optimization mode,
// / 从 `内置` module, including Zig version, optimization 模式,
// / target platform details, and linking options.
// / target platform details, 和 linking options.
pub fn main() !void {
    // Allocate a buffer for stdout buffering to reduce system calls
    // 分配 一个 缓冲区 用于 stdout buffering 到 reduce system calls
    var stdout_buffer: [1024]u8 = undefined;
    // Create a buffered writer for stdout to improve I/O performance
    // 创建一个 缓冲写入器 用于 stdout 到 improve I/O performance
    var file_writer = std.fs.File.stdout().writer(&stdout_buffer);
    // Obtain the generic writer interface for formatted output
    // Obtain 通用 writer 接口 用于 格式化 输出
    const out = &file_writer.interface;

    // Print the Zig compiler version string embedded at compile time
    // 打印 Zig compiler version string embedded 在 编译时
    try out.print("zig version (compiler): {s}\n", .{builtin.zig_version_string});
    
    // Print the optimization mode and its corresponding description
    // 打印 optimization 模式 和 its 对应的 描述
    try out.print("optimize mode: {s} — {s}\n", .{ @tagName(builtin.mode), optimize_hint });
    
    // Print the target triple: architecture, OS, and ABI
    // 打印 target triple: architecture, OS, 和 ABI
    // These values reflect the platform for which the binary was compiled
    // 这些 值 reflect platform 用于 which binary was compiled
    try out.print(
        "target triple: {s}-{s}-{s}\n",
        .{
            @tagName(builtin.target.cpu.arch),
            @tagName(builtin.target.os.tag),
            @tagName(builtin.target.abi),
        },
    );
    
    // Indicate whether the binary was built in single-threaded mode
    // Indicate whether binary was built 在 single-threaded 模式
    try out.print("single-threaded build: {}\n", .{builtin.single_threaded});
    
    // Indicate whether the standard C library (libc) is linked
    // Indicate whether 标准 C 库 (libc) is linked
    try out.print("linking libc: {}\n", .{builtin.link_libc});

    // Compile-time block to conditionally import test helpers when running tests.
    // 编译-time block 到 conditionally 导入 test helpers 当 running tests.
    // This demonstrates using `builtin.is_test` to enable test-only code paths.
    // 此 演示 使用 `内置.is_test` 到 enable test-only 代码 路径.
    comptime {
        if (builtin.is_test) {
            // The root module could enable test-only helpers using this hook.
            // root module could enable test-only helpers 使用 此 hook.
            _ = @import("test_helpers.zig");
        }
    }

    // Flush the buffered writer to ensure all output is written to stdout
    // 刷新 缓冲写入器 到 确保 所有 输出 is written 到 stdout
    try out.flush();
}
