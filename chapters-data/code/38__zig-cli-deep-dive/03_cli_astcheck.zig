// ! 用于 CLI 环境配置和跨平台默认设置的实用函数。
// ! 该模块提供用于确定缓存目录、颜色支持、
// ! 以及基于目标操作系统的默认工具配置的帮助程序。
const std = @import("std");
const builtin = @import("builtin");

// / 返回缓存目录的适当环境变量键
// / 基于目标操作系统。
///
// / - Windows 使用 LOCALAPPDATA 作为应用程序缓存
// / - macOS 和 iOS 使用 HOME（缓存通常位于 ~/Library/Caches 中）
// / - 类 Unix 系统倾向于使用 XDG_CACHE_HOME 来符合 XDG 基本目录规范
// / - 其他系统回退到 HOME 目录
pub fn defaultCacheEnvKey() []const u8 {
    return switch (builtin.os.tag) {
        .windows => "LOCALAPPDATA",
        .macos => "HOME",
        .ios => "HOME",
        .linux, .freebsd, .netbsd, .openbsd, .dragonfly, .haiku => "XDG_CACHE_HOME",
        else => "HOME",
    };
}

// / 确定终端输出中是否应使用 ANSI 颜色代码
// / 基于标准环境变量。
///
// / 遵循非正式标准：
// / - NO_COLOR（任何值）禁用颜色
// / - CLICOLOR_FORCE（任何值）强制使用颜色，即使不是 TTY
// / - 默认行为是启用颜色
///
// / 如果应使用 ANSI 颜色则返回 true，否则返回 false。
pub fn preferAnsiColor(env: std.process.EnvMap) bool {
    // Check if colors are explicitly disabled
    if (env.get("NO_COLOR")) |_| return false;
    // Check if colors are explicitly forced
    if (env.get("CLICOLOR_FORCE")) |_| return true;
    // Default to enabling colors
    return true;
}

// / 返回用于调用 Zig 格式化程序的默认命令行参数
// / 在检查模式下（报告格式问题而不修改文件）。
pub fn defaultFormatterArgs() []const []const u8 {
    return &.{ "zig", "fmt", "--check" };
}
