// File: chapters-data/code/02__control-flow-essentials/branching.zig

// Demonstrates Zig's control flow and optional handling capabilities
// 演示Zig的控制流和可选值处理能力
const std = @import("std");

/// Determines a descriptive label for an optional integer value.
/// 为可选整数确定描述性标签
/// Uses labeled blocks to handle different numeric cases cleanly.
/// 使用带标签的代码块简洁处理不同的数值情况
/// Returns a string classification based on the value's properties.
/// 返回基于值属性的字符串分类
fn chooseLabel(value: ?i32) []const u8 {
    // Unwrap the optional value using payload capture syntax
    // 使用载荷捕获语法解包可选值
    return if (value) |v| blk: {
        // Check for zero first
        // 首先检查是否为零
        if (v == 0) break :blk "zero";
        // Positive numbers
        // 正数
        if (v > 0) break :blk "positive";
        // All remaining cases are negative
        // 所有剩余情况都是负数
        break :blk "negative";
    } else "missing";
    // Handle null case
    // 处理空值情况
}

pub fn main() !void {
    // Array containing both present and absent (null) values
    // 包含存在值和空值的数组
    const samples = [_]?i32{ 5, 0, null, -3 };

    // Iterate through samples with index capture
    // 遍历样本并捕获索引
    for (samples, 0..) |item, index| {
        // Classify each sample value
        // 对每个样本值进行分类
        const label = chooseLabel(item);
        // Display the index and corresponding label
        // 显示索引和对应的标签
        std.debug.print("sample {d}: {s}\n", .{ index, label });
    }
}
