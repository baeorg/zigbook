
// Import the standard library for testing utilities
// 导入标准库 用于 testing utilities
const std = @import("std");

// Defines the three tonal categories for styled output
// Defines 三个 tonal categories 用于 styled 输出
pub const Tone = enum { stable, watch, alert };

// Represents a color theme with ANSI escape codes for different tones
// Represents 一个 color theme 使用 ANSI escape codes 用于 different tones
// Each tone has a start sequence and there's a shared reset sequence
// 每个 tone has 一个 start sequence 和 there's 一个 shared reset sequence
pub const Theme = struct {
    stable_start: []const u8,
    watch_start: []const u8,
    alert_start: []const u8,
    reset: []const u8,

    // Returns the appropriate ANSI start sequence for the given tone
    // 返回 appropriate ANSI start sequence 用于 given tone
    pub fn start(self: Theme, tone: Tone) []const u8 {
        return switch (tone) {
            .stable => self.stable_start,
            .watch => self.watch_start,
            .alert => self.alert_start,
        };
    }
};

// Creates a default theme with standard terminal colors:
// Creates 一个 默认 theme 使用 标准 terminal colors:
// stable (green), watch (yellow), alert (red)
pub fn defaultTheme() Theme {
    return Theme{
        .stable_start = "\x1b[32m", // green
        .watch_start = "\x1b[33m",  // yellow
        .alert_start = "\x1b[31m",  // red
        .reset = "\x1b[0m",
    };
}

// Writes styled text to the provided writer by wrapping it with
// Writes styled text 到 provided writer 通过 wrapping it 使用
// ANSI color codes based on the theme and tone
// ANSI color codes 基于 theme 和 tone
pub fn writeStyled(theme: Theme, tone: Tone, writer: anytype, text: []const u8) !void {
    try writer.print("{s}{s}{s}", .{ theme.start(tone), text, theme.reset });
}

// Verifies that the default theme returns correct ANSI escape codes
// Verifies 该 默认 theme 返回 correct ANSI escape codes
test "default theme colors" {
    const theme = defaultTheme();
    try std.testing.expectEqualStrings("\x1b[32m", theme.start(.stable));
    try std.testing.expectEqualStrings("\x1b[0m", theme.reset);
}
