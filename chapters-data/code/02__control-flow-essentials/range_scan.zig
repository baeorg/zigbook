// 文件路径: chapters-data/code/02__control-flow-essentials/range_scan.zig

// 演示带标签break和continue语句的while循环
const std = @import("std");

pub fn main() !void {
    // 示例数据数组，包含混合的正数、负数和零值
    const data = [_]i16{ 12, 5, 9, -1, 4, 0 };

    // 搜索数组中的第一个负值
    var index: usize = 0;
    // while-else结构：break提供值，else提供回退
    const first_negative = while (index < data.len) : (index += 1) {
        // 检查当前元素是否为负数
        if (data[index] < 0) break index;
    } else null; // 扫描整个数组后未找到负值

    // 报告负值搜索结果
    if (first_negative) |pos| {
        std.debug.print("first negative at index {d}\n", .{pos});
    } else {
        std.debug.print("no negatives in sequence\n", .{});
    }

    // 累积偶数之和直到遇到零
    var sum: i64 = 0;
    var count: usize = 0;

    // 为循环添加标签以启用显式break定位
    accumulate: while (count < data.len) : (count += 1) {
        const value = data[count];
        // 遇到零时停止累积
        if (value == 0) {
            std.debug.print("encountered zero, breaking out\n", .{});
            break :accumulate;
        }
        // 使用带标签的continue跳过奇数值
        if (@mod(value, 2) != 0) continue :accumulate;
        // 将偶数值加到运行总和
        sum += value;
    }

    // 显示零之前的偶数前缀值的累积和
    std.debug.print("sum of even prefix values = {d}\n", .{sum});
}
