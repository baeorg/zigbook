// 此程序演示如何在Zig的构建系统中使用自定义模块。
// 它导入本地"math"模块并使用其函数执行基本算术运算。

// 导入标准库以获取调试打印功能
const std = @import("std");
// 导入提供算术运算的自定义数学模块
const math = @import("math");

// 主入口点，演示使用基本算术的模块用法
pub fn main() !void {
    // 定义两个常量操作数用于演示
    const a = 10;
    const b = 20;

    // 使用导入的数学模块打印加法结果
    std.debug.print("{d} + {d} = {d}\n", .{ a, b, math.add(a, b) });

    // 使用导入的数学模块打印乘法结果
    std.debug.print("{d} * {d} = {d}\n", .{ a, b, math.multiply(a, b) });
}
