// File: chapters-data/code/02__control-flow-essentials/loop_labels.zig

// Demonstrates labeled loops and while-else constructs in Zig
// 演示Zig中的带标签循环和while-else结构
const std = @import("std");

/// Searches for the first row where both elements are even numbers.
/// 查找第一个两元素都为偶数的行
/// Uses a while loop with continue statements to skip invalid rows.
/// 使用while循环和continue语句跳过无效行
/// Returns the zero-based index of the matching row, or null if none found.
/// 返回匹配行的基于零的索引，如果未找到则返回null
fn findAllEvenPair(rows: []const [2]i32) ?usize {
    // Track current row index during iteration
    // 在迭代期间跟踪当前行索引
    var row: usize = 0;
    // while-else construct: break provides value, else provides fallback
    // while-else结构：break提供值，else提供回退
    const found = while (row < rows.len) : (row += 1) {
        // Extract current pair for examination
        // 提取当前对进行检查
        const pair = rows[row];
        // Skip row if first element is odd
        // 如果第一个元素是奇数则跳过该行
        if (@mod(pair[0], 2) != 0) continue;
        // Skip row if second element is odd
        // 如果第二个元素是奇数则跳过该行
        if (@mod(pair[1], 2) != 0) continue;
        // Both elements are even: return this row's index
        // 两个元素都是偶数：返回此行的索引
        break row;
    } else null; // No matching row found after exhausting all rows

    return found;
}

pub fn main() !void {
    // Test data containing pairs of integers with mixed even/odd values
    // Test 数据 containing pairs 的 整数 使用 mixed even/odd 值
    const grid = [_][2]i32{
        .{ 3, 7 }, // Both odd
        .{ 2, 4 }, // Both even (target)
        .{ 5, 6 }, // Mixed
    };

    // Search for first all-even pair and report result
    // Search 用于 首先 所有-even pair 和 report result
    if (findAllEvenPair(&grid)) |row| {
        std.debug.print("first all-even row: {d}\n", .{row});
    } else {
        std.debug.print("no all-even rows\n", .{});
    }

    // Demonstrate labeled loop for multi-level break control
    // Demonstrate labeled loop 用于 multi-level break control
    var attempts: usize = 0;
    // Label the outer while loop to enable breaking from nested for loop
    // 标签 outer 当 loop 到 enable breaking 从 nested 用于 loop
    outer: while (attempts < grid.len) : (attempts += 1) {
        // Iterate through columns of current row with index capture
        // 遍历 columns 的 当前 row 使用 索引捕获
        for (grid[attempts], 0..) |value, column| {
            // Check if target value is found
            // 检查 如果 target 值 is found
            if (value == 4) {
                // Report location of target value
                // Report location 的 target 值
                std.debug.print(
                    "found target value at row {d}, column {d}\n",
                    .{ attempts, column },
                );
                // Break out of both loops using the outer label
                // Break out 的 both loops 使用 outer 标签
                break :outer;
            }
        }
    }
}
