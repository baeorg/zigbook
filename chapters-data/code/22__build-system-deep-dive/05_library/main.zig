
// Import the standard library for printing capabilities
// 导入标准库 用于 printing capabilities
const std = @import("std");

// External function declaration: doubles the input integer
// External 函数 declaration: doubles 输入 integer
// This function is defined in a separate library/object file
// 此 函数 is defined 在 一个 separate 库/object 文件
extern fn util_double(x: i32) i32;

// External function declaration: squares the input integer
// External 函数 declaration: squares 输入 integer
// This function is defined in a separate library/object file
// 此 函数 is defined 在 一个 separate 库/object 文件
extern fn util_square(x: i32) i32;

// Main entry point demonstrating library linking
// 主 程序入口点 demonstrating 库 linking
// Calls external utility functions to show build system integration
// Calls external 工具函数 函数 到 show 构建 system integration
pub fn main() !void {
    // Test value for demonstrating the external functions
    // Test 值 用于 demonstrating external 函数
    const x: i32 = 7;
    
    // Print the result of doubling x using the external function
    // 打印 result 的 doubling x 使用 external 函数
    std.debug.print("double({d}) = {d}\n", .{ x, util_double(x) });
    
    // Print the result of squaring x using the external function
    // 打印 result 的 squaring x 使用 external 函数
    std.debug.print("square({d}) = {d}\n", .{ x, util_square(x) });
}
