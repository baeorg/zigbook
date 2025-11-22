// Import the standard library for testing utilities
// 导入标准库以获取测试工具
const std = @import("std");

// Defines the three tonal categories for styled output
// 定义样式化输出的三种色调类别
pub const Tone = enum { stable, watch, alert };

// Represents a color theme with ANSI escape codes for different tones
// 表示带有 ANSI 转义代码的颜色主题，用于不同的色调
// Each tone has a start sequence and there's a shared reset sequence
// 每种色调都有一个开始序列和一个共享的重置序列
pub const Theme = struct {
    stable_start: []const u8,
    watch_start: []const u8,
    alert_start: []const u8,
    reset: []const u8,

    // Returns the appropriate ANSI start sequence for the given tone
    // 返回给定色调的相应 ANSI 开始序列
    pub fn start(self: Theme, tone: Tone) []const u8 {
        return switch (tone) {
            .stable => self.stable_start,
            .watch => self.watch_start,
            .alert => self.alert_start,
        };
    }
};

// Creates a default theme with standard terminal colors:
// 创建具有标准终端颜色的默认主题：
// stable (green), watch (yellow), alert (red)
// 稳定（绿色），观察（黄色），警报（红色）
pub fn defaultTheme() Theme {
    return Theme{
        .stable_start = "\x1b[32m", // green
        .watch_start = "\x1b[33m", // yellow
        .alert_start = "\x1b[31m", // red
        .reset = "\x1b[0m",
    };
}

// Writes styled text to the provided writer by wrapping it with
// 通过用 ANSI 颜色代码包装它，将样式化文本写入提供的写入器
// ANSI color codes based on the theme and tone
// 基于主题和色调
pub fn writeStyled(theme: Theme, tone: Tone, writer: anytype, text: []const u8) !void {
    try writer.print("{s}{s}{s}", .{ theme.start(tone), text, theme.reset });
}

// Verifies that the default theme returns correct ANSI escape codes
// 验证默认主题返回正确的 ANSI 转义代码
test "default theme colors" {
    const theme = defaultTheme();
    try std.testing.expectEqualStrings("\x1b[32m", theme.start(.stable));
    try std.testing.expectEqualStrings("\x1b[0m", theme.reset);
}
