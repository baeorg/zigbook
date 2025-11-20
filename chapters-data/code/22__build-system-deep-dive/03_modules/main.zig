// This program demonstrates how to use custom modules in Zig's build system.
// 此 program 演示 how 到 use 自定义 modules 在 Zig's 构建 system.
// It imports a local "math" module and uses its functions to perform basic arithmetic operations.
// It imports 一个 local "math" module 和 使用 its 函数 到 执行 basic arithmetic operations.

// Import the standard library for debug printing capabilities
// 导入标准库 用于 调试 printing capabilities
const std = @import("std");
// Import the custom math module which provides arithmetic operations
// 导入 自定义 math module which provides arithmetic operations
const math = @import("math");

// Main entry point demonstrating module usage with basic arithmetic
// 主 程序入口点 demonstrating module usage 使用 basic arithmetic
pub fn main() !void {
    // Define two constant operands for demonstration
    // 定义 两个 constant operands 用于 demonstration
    const a = 10;
    const b = 20;
    
    // Print the result of addition using the imported math module
    // 打印 result 的 addition 使用 imported math module
    std.debug.print("{d} + {d} = {d}\n", .{ a, b, math.add(a, b) });
    
    // Print the result of multiplication using the imported math module
    // 打印 result 的 multiplication 使用 imported math module
    std.debug.print("{d} * {d} = {d}\n", .{ a, b, math.multiply(a, b) });
}
