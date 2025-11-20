// ! Utility functions for CLI environment configuration and cross-platform defaults.
// ! 工具函数 函数 用于 命令行工具 environment configuration 和 cross-platform defaults.
// ! This module provides helpers for determining cache directories, color support,
// ! 此 module provides helpers 用于 determining cache directories, color support,
// ! and default tool configurations based on the target operating system.
// ! 和 默认 tool configurations 基于 target operating system.
const std = @import("std");
const builtin = @import("builtin");

// / Returns the appropriate environment variable key for the cache directory
// / 返回 appropriate environment variable key 用于 cache directory
// / based on the target operating system.
// / 基于 target operating system.
///
// / - Windows uses LOCALAPPDATA for application cache
// / - Windows 使用 LOCALAPPDATA 用于 application cache
// / - macOS and iOS use HOME (cache typically goes in ~/Library/Caches)
// / - macOS 和 iOS use HOME (cache typically goes 在 ~/库/Caches)
// / - Unix-like systems prefer XDG_CACHE_HOME for XDG Base Directory compliance
// / - Unix-like systems prefer XDG_CACHE_HOME 用于 XDG Base Directory compliance
// / - Other systems fall back to HOME directory
// / - Other systems fall back 到 HOME directory
pub fn defaultCacheEnvKey() []const u8 {
    return switch (builtin.os.tag) {
        .windows => "LOCALAPPDATA",
        .macos => "HOME",
        .ios => "HOME",
        .linux, .freebsd, .netbsd, .openbsd, .dragonfly, .haiku => "XDG_CACHE_HOME",
        else => "HOME",
    };
}

// / Determines whether ANSI color codes should be used in terminal output
// / Determines whether ANSI color codes should be used 在 terminal 输出
// / based on standard environment variables.
// / 基于 标准 environment variables.
///
// / Follows the informal standard where:
// / Follows informal 标准 where:
// / - NO_COLOR (any value) disables colors
// / - NO_COLOR (any 值) disables colors
// / - CLICOLOR_FORCE (any value) forces colors even if not a TTY
// / - CLICOLOR_FORCE (any 值) forces colors even 如果 不 一个 TTY
// / - Default behavior is to enable colors
// / - 默认 behavior is 到 enable colors
///
// / Returns true if ANSI colors should be used, false otherwise.
// / 返回 true 如果 ANSI colors should be used, false otherwise.
pub fn preferAnsiColor(env: std.process.EnvMap) bool {
    // Check if colors are explicitly disabled
    // 检查 如果 colors are explicitly disabled
    if (env.get("NO_COLOR")) |_| return false;
    // Check if colors are explicitly forced
    // 检查 如果 colors are explicitly forced
    if (env.get("CLICOLOR_FORCE")) |_| return true;
    // Default to enabling colors
    // 默认 到 enabling colors
    return true;
}

// / Returns the default command-line arguments for invoking the Zig formatter
// / 返回 默认 command-line arguments 用于 invoking Zig formatter
// / in check mode (reports formatting issues without modifying files).
// / 在 检查 模式 (reports formatting issues without modifying 文件).
pub fn defaultFormatterArgs() []const []const u8 {
    return &.{ "zig", "fmt", "--check" };
}
