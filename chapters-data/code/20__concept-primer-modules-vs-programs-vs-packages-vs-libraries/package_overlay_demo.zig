// Import the standard library for common utilities and types
// 导入标准库 用于 common utilities 和 类型
const std = @import("std");
// Import builtin module to access compile-time information about the build
// 导入 内置 module 以访问 编译-time 信息 about 构建
const builtin = @import("builtin");
// Import the overlay module by name as it will be registered via --dep/-M on the CLI
// 导入 overlay module 通过 name 作为 it will be registered via --dep/-M 在 命令行工具
const overlay = @import("overlay");

// / Entry point for the package overlay demonstration program.
// / 程序入口点 用于 package overlay demonstration program.
// / Demonstrates how to use the overlay_widget library to display package information
// / 演示 how 到 use overlay_widget 库 到 显示 package 信息
// / including build mode and target operating system details.
// / including 构建模式 和 target operating system details.
pub fn main() !void {
    // Allocate a fixed-size buffer on the stack for stdout operations
    // 分配 一个 固定大小缓冲区 在 栈 用于 stdout operations
    // This avoids heap allocation for simple output scenarios
    // 此 avoids 堆 allocation 用于 simple 输出 scenarios
    var stdout_buffer: [512]u8 = undefined;
    // Create a buffered writer for stdout to improve performance by batching writes
    // 创建一个 缓冲写入器 用于 stdout 到 improve performance 通过 batching writes
    var file_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &file_writer.interface;

    // Populate package details structure with information about the current package
    // Populate package details structure 使用 信息 about 当前 package
    // This includes compile-time information like optimization mode and target OS
    // 此 includes 编译-time 信息 like optimization 模式 和 target OS
    const details = overlay.PackageDetails{
        .package_name = "overlay",
        .role = "library package",
        // Extract the optimization mode name (e.g., Debug, ReleaseFast) at compile time
        // Extract optimization 模式 name (e.g., 调试, ReleaseFast) 在 编译时
        .optimize_mode = @tagName(builtin.mode),
        // Extract the target OS name (e.g., linux, windows) at compile time
        // Extract target OS name (e.g., linux, windows) 在 编译时
        .target_os = @tagName(builtin.target.os.tag),
    };

    // Render the package summary to stdout using the overlay library
    // Render package summary 到 stdout 使用 overlay 库
    try overlay.renderSummary(stdout, details);
    // Ensure all buffered output is written to the terminal
    // 确保 所有 缓冲 输出 is written 到 terminal
    try stdout.flush();
}
