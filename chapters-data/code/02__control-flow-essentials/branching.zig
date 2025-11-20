// File: chapters-data/code/02__control-flow-essentials/branching.zig

// Demonstrates Zig's control flow and optional handling capabilities
// 演示 Zig's 控制流 和 可选 handling capabilities
const std = @import("std");

// / Determines a descriptive label for an optional integer value.
// / Determines 一个 描述性标签 用于 一个 可选 integer 值.
// / Uses labeled blocks to handle different numeric cases cleanly.
// / 使用 带标签的代码块 到 处理 different numeric 情况 简洁地.
// / Returns a string classification based on the value's properties.
// / 返回 一个 string 分类 基于 值的属性.
fn chooseLabel(value: ?i32) []const u8 {
    // Unwrap the optional value using payload capture syntax
    // 解包 可选值 使用 载荷捕获 语法
    return if (value) |v| blk: {
        // Check for zero first
        // 检查 零 首先
        if (v == 0) break :blk "zero";
        // Positive numbers
        // 正数 数字
        if (v > 0) break :blk "positive";
        // All remaining cases are negative
        // 所有 remaining 情况 are 负数
        break :blk "negative";
    } else "missing"; // Handle null case
}

pub fn main() !void {
    // Array containing both present and absent (null) values
    // 数组 containing both 存在 和 absent (空) 值
    const samples = [_]?i32{ 5, 0, null, -3 };

    // Iterate through samples with index capture
    // 遍历 样本 使用 索引捕获
    for (samples, 0..) |item, index| {
        // Classify each sample value
        // 分类 每个 样本值
        const label = chooseLabel(item);
        // Display the index and corresponding label
        // 显示 索引 和 对应的 标签
        std.debug.print("sample {d}: {s}\n", .{ index, label });
    }
}
