// ! Discovery probe utility demonstrating conditional imports and runtime introspection.
// ! Discovery probe 工具函数 demonstrating conditional imports 和 runtime introspection.
// ! This module showcases how to use compile-time conditionals to optionally load
// ! 此 module showcases how 到 use 编译-time conditionals 到 optionally load
// ! development tools and query their capabilities at runtime using reflection.
// ! development tools 和 query their capabilities 在 runtime 使用 reflection.

const std = @import("std");
const builtin = @import("builtin");

// / Conditionally import development hooks based on build mode.
// / Conditionally 导入 development hooks 基于 构建模式.
// / In Debug mode, imports the full dev_probe module with diagnostic capabilities.
// / 在 调试模式, imports 满 dev_probe module 使用 diagnostic capabilities.
// / In other modes (ReleaseSafe, ReleaseFast, ReleaseSmall), provides a minimal
// / 在 other modes (ReleaseSafe, ReleaseFast, ReleaseSmall), provides 一个 最小化
// / stub implementation to avoid loading unnecessary development tooling.
// / stub implementation 到 avoid loading unnecessary development tooling.
///
// / This pattern enables zero-cost abstractions where development features are
// / 此 pattern enables 零-cost abstractions where development features are
// / completely elided from release builds while maintaining a consistent API.
// / completely elided 从 发布 builds 当 maintaining 一个 consistent API.
pub const DevHooks = if (builtin.mode == .Debug)
    @import("tools/dev_probe.zig")
else
    struct {
        // / Minimal stub implementation for non-debug builds.
        // / 最小化 stub implementation 用于 non-调试 builds.
        // / Returns a static message indicating development hooks are disabled.
        // / 返回 一个 static message indicating development hooks are disabled.
        pub fn banner() []const u8 {
            return "dev hooks disabled";
        }
    };

// / Entry point demonstrating module discovery and conditional feature detection.
// / 程序入口点 demonstrating module discovery 和 conditional feature detection.
// / This function showcases:
// / 此 函数 showcases:
// / 1. The new Zig 0.15.2 buffered writer API for stdout
// / 1. 新 Zig 0.15.2 缓冲写入器 API 用于 stdout
// / 2. Compile-time conditional imports (DevHooks)
// / 2. 编译-time conditional imports (DevHooks)
// / 3. Runtime introspection using @hasDecl to probe for optional functions
// / 3. Runtime introspection 使用 @hasDecl 到 probe 用于 可选 函数
pub fn main() !void {
    // Create a stack-allocated buffer for stdout operations
    // 创建一个 栈-allocated 缓冲区 用于 stdout operations
    var stdout_buffer: [512]u8 = undefined;
    
    // Initialize a file writer with our buffer. This is part of the Zig 0.15.2
    // Initialize 一个 文件 writer 使用 our 缓冲区. 此 is part 的 Zig 0.15.2
    // I/O revamp where writers now require explicit buffer management.
    // I/O revamp where writers now require explicit 缓冲区 management.
    var file_writer = std.fs.File.stdout().writer(&stdout_buffer);
    
    // Obtain the generic writer interface for formatted output
    // Obtain 通用 writer 接口 用于 格式化 输出
    const stdout = &file_writer.interface;

    // Report the current build mode (Debug, ReleaseSafe, ReleaseFast, ReleaseSmall)
    // Report 当前 构建模式 (调试, ReleaseSafe, ReleaseFast, ReleaseSmall)
    try stdout.print("discovery mode: {s}\n", .{@tagName(builtin.mode)});
    
    // Call the always-available banner() function from DevHooks.
    // Call always-available banner() 函数 从 DevHooks.
    // The implementation varies based on whether we're in Debug mode or not.
    // implementation varies 基于 whether we're 在 调试模式 或 不.
    try stdout.print("dev hooks: {s}\n", .{DevHooks.banner()});

    // Use @hasDecl to check if the buildSession() function exists in DevHooks.
    // Use @hasDecl 到 检查 如果 buildSession() 函数 存在 在 DevHooks.
    // This demonstrates runtime discovery of optional capabilities without
    // 此 演示 runtime discovery 的 可选 capabilities without
    // requiring all implementations to provide every function.
    // requiring 所有 implementations 到 provide 每个 函数.
    if (@hasDecl(DevHooks, "buildSession")) {
        // buildSession() is only available in the full dev_probe module (Debug builds)
        // buildSession() is only available 在 满 dev_probe module (调试 builds)
        try stdout.print("built with zig {s}\n", .{DevHooks.buildSession()});
    } else {
        // In release builds, the stub DevHooks doesn't provide buildSession()
        // 在 发布 builds, stub DevHooks doesn't provide buildSession()
        try stdout.print("no buildSession() exported\n", .{});
    }

    // Flush the buffered output to ensure all content is written to stdout
    // 刷新 缓冲 输出 到 确保 所有 content is written 到 stdout
    try stdout.flush();
}
