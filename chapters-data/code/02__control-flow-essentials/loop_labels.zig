// File: chapters-data/code/02__control-flow-essentials/loop_labels.zig

// Demonstrates labeled loops and while-else constructs in Zig
// 演示 labeled loops 和 当-否则 constructs 在 Zig
const std = @import("std");

// / Searches for the first row where both elements are even numbers.
// / Searches 用于 首先 row where both elements are even 数字.
// / Uses a while loop with continue statements to skip invalid rows.
// / 使用 一个 当 loop 使用 continue statements 到 skip 无效 rows.
// / Returns the zero-based index of the matching row, or null if none found.
// / 返回 零-based 索引 的 matching row, 或 空 如果 none found.
fn findAllEvenPair(rows: []const [2]i32) ?usize {
    // Track current row index during iteration
    // Track 当前 row 索引 during iteration
    var row: usize = 0;
    // while-else construct: break provides value, else provides fallback
    // 当-否则 construct: break provides 值, 否则 provides fallback
    const found = while (row < rows.len) : (row += 1) {
        // Extract current pair for examination
        // Extract 当前 pair 用于 examination
        const pair = rows[row];
        // Skip row if first element is odd
        // Skip row 如果 首先 element is odd
        if (@mod(pair[0], 2) != 0) continue;
        // Skip row if second element is odd
        // Skip row 如果 second element is odd
        if (@mod(pair[1], 2) != 0) continue;
        // Both elements are even: return this row's index
        // Both elements are even: 返回 此 row's 索引
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
