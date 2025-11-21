// File: chapters-data/code/02__control-flow-essentials/switch_examples.zig

// Import the standard library for I/O operations
// 导入标准库用于I/O操作
const std = @import("std");

// Define an enum representing different compilation modes
// 定义一个枚举，表示不同的编译模式
const Mode = enum { fast, safe, tiny };

/// Converts a numeric score into a descriptive text message.
/// 将数值分数转换为描述性文本消息。
/// Demonstrates switch expressions with ranges, multiple values, and catch-all cases.
/// 演示switch表达式的范围匹配、多值匹配和通配符匹配用法。
/// Returns a string literal describing the score's progress level.
/// 返回描述分数进度级别的字符串字面量。
fn describeScore(score: u8) []const u8 {
    return switch (score) {
        0 => "no progress",           // Exact match for zero
        1...3 => "warming up",         // Range syntax: matches 1, 2, or 3
        4, 5 => "halfway there",       // Multiple discrete values
        6...9 => "almost done",        // Range: matches 6 through 9
        10 => "perfect run",           // Maximum valid score
        else => "out of range",        // Catch-all for any other value
    };
}

pub fn main() !void {
    // Array of test scores to demonstrate switch behavior
    // 测试分数数组，用于演示switch行为
    const samples = [_]u8{ 0, 2, 5, 8, 10, 12 };

    // Iterate through each score and print its description
    // 遍历每个分数并打印其描述
    for (samples) |score| {
        std.debug.print("{d}: {s}\n", .{ score, describeScore(score) });
    }

    // Demonstrate switch with enum values
    // 演示与枚举值一起使用的switch语句
    const mode: Mode = .safe;

    // Switch on enum to assign different numeric factors based on mode
    // 基于枚举值切换，根据模式分配不同的数值因子
    // All enum cases must be handled (exhaustive matching)
    // 必须处理所有枚举情况（穷尽性匹配）
    const factor = switch (mode) {
        .fast => 32,  // Optimization for speed
        .safe => 16,  // Balanced mode
        .tiny => 4,   // Optimization for size
    };

    // Print the selected mode and its corresponding factor
    // 打印选中的模式及其对应的因子
    std.debug.print("mode {s} -> factor {d}\n", .{ @tagName(mode), factor });
}
