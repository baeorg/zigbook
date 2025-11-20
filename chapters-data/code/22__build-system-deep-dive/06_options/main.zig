
// Import standard library for debug printing functionality
// 导入 标准库 用于 调试 printing functionality
const std = @import("std");
// Import build-time configuration options defined in build.zig
// 导入 构建-time configuration options defined 在 构建.zig
const config = @import("config");

// / Entry point of the application demonstrating the use of build options.
// / 入口点 application demonstrating use 的 构建 options.
// / This function showcases how to access and use configuration values that
// / 此 函数 showcases how 以访问 和 use configuration 值 该
// / are set during the build process through the Zig build system.
// / are set during 构建 process through Zig 构建 system.
pub fn main() !void {
    // Display the application name from build configuration
    // 显示 application name 从 构建 configuration
    std.debug.print("Application: {s}\n", .{config.app_name});
    // Display the logging toggle status from build configuration
    // 显示 logging toggle 状态 从 构建 configuration
    std.debug.print("Logging enabled: {}\n", .{config.enable_logging});

    // Conditionally execute debug logging based on build-time configuration
    // Conditionally execute 调试 logging 基于 构建-time configuration
    // This demonstrates compile-time branching using build options
    // 此 演示 编译-time 分支 使用 构建 options
    if (config.enable_logging) {
        std.debug.print("[DEBUG] This is a debug message\n", .{});
    }
}
