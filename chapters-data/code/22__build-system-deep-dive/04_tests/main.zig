// Main entry point demonstrating the factorial function from mylib.
// 主 程序入口点 demonstrating factorial 函数 从 mylib.
// This example shows how to:
// 此 示例 shows how 到:
// - Import and use custom library modules
// - 导入 和 use 自定义 库 modules
// - Call library functions with different input values
// - Call 库 函数 使用 different 输入 值
// - Display computed results using debug printing
// - 显示 computed results 使用 调试 printing
const std = @import("std");
const mylib = @import("mylib");

pub fn main() !void {
    std.debug.print("5! = {d}\n", .{mylib.factorial(5)});
    std.debug.print("10! = {d}\n", .{mylib.factorial(10)});
}
