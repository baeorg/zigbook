// Import the standard library for printing capabilities
const std = @import("std");

// 外部函数声明：将输入整数翻倍
// 此函数在单独的库/对象文件中定义
extern fn util_double(x: i32) i32;

// 外部函数声明：将输入整数平方
// 此函数在单独的库/对象文件中定义
extern fn util_square(x: i32) i32;

// 演示库链接的主入口点
// 调用外部工具函数以展示构建系统集成
pub fn main() !void {
    // 用于演示外部函数的测试值
    const x: i32 = 7;

    // 使用外部函数打印 x 翻倍的结果
    std.debug.print("double({d}) = {d}\n", .{ x, util_double(x) });

    // 使用外部函数打印 x 平方 Results
    std.debug.print("square({d}) = {d}\n", .{ x, util_square(x) });
}
