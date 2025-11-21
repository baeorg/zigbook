// 文件路径: chapters-data/code/02__control-flow-essentials/loop_labels.zig

// 演示Zig中的带标签循环和while-else结构
const std = @import("std");

/// 查找第一个两元素都为偶数的行
/// 使用while循环和continue语句跳过无效行
/// 返回匹配行的基于零的索引，如果未找到则返回null
fn findAllEvenPair(rows: []const [2]i32) ?usize {
    // 在迭代期间跟踪当前行索引
    var row: usize = 0;
    // while-else结构：break提供值，else提供回退
    const found = while (row < rows.len) : (row += 1) {
        // 提取当前对进行检查
        const pair = rows[row];
        // 如果第一个元素是奇数则跳过该行
        if (@mod(pair[0], 2) != 0) continue;
        // 如果第二个元素是奇数则跳过该行
        if (@mod(pair[1], 2) != 0) continue;
        // 两个元素都是偶数：返回此行的索引
        break row;
    } else null; // 耗尽所有行后未找到匹配行

    return found;
}

pub fn main() !void {
    // 测试数据，包含混合奇偶值的整数对
    const grid = [_][2]i32{
        .{ 3, 7 }, // 两者都是奇数
        .{ 2, 4 }, // 两者都是偶数（目标）
        .{ 5, 6 }, // 混合
    };

    // 查找第一个全偶数对并报告结果
    if (findAllEvenPair(&grid)) |row| {
        std.debug.print("first all-even row: {d}\n", .{row});
    } else {
        std.debug.print("no all-even rows\n", .{});
    }

    // 演示用于多级break控制的带标签循环
    var attempts: usize = 0;
    // 为外部while循环添加标签以启用从嵌套for循环跳出
    outer: while (attempts < grid.len) : (attempts += 1) {
        // 遍历当前行的列并捕获索引
        for (grid[attempts], 0..) |value, column| {
            // 检查是否找到目标值
            if (value == 4) {
                // 报告目标值的位置
                std.debug.print(
                    "found target value at row {d}, column {d}\n",
                    .{ attempts, column },
                );
                // 使用外部标签跳出两个循环
                break :outer;
            }
        }
    }
}
