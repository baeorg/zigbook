
// Import standard library for debug printing functionality
// 导入标准库用于调试打印功能
const std = @import("std");
// Import build-time configuration options defined in build.zig
// 从 build.zig 导入构建时配置选项
const config = @import("config");

// / 应用程序的入口点，演示构建选项的使用。
// / 此函数展示了如何通过 Zig 构建系统访问和使用在构建过程中设置的配置值。
pub fn main() !void {
    // 显示构建配置中的应用程序名称
    std.debug.print("Application: {s}\n", .{config.app_name});
    // 显示构建配置中的日志开关状态
    std.debug.print("Logging enabled: {}\n", .{config.enable_logging});

    // 根据构建时配置有条件地执行调试日志记录
    // 这演示了使用构建选项的编译时分支
    if (config.enable_logging) {
        std.debug.print("[DEBUG] This is a debug message\n", .{});
    }
}
