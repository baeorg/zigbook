// This module provides basic arithmetic operations for the zigbook build system examples.
// 此 module provides basic arithmetic operations 用于 zigbook 构建 system 示例.
// It demonstrates how to create a reusable module that can be imported by other Zig files.
// It 演示 how 到 创建一个 reusable module 该 can be imported 通过 other Zig 文件.

// / Adds two 32-bit signed integers and returns their sum.
// / Adds 两个 32-bit signed 整数 和 返回 their sum.
// / This function is marked pub to be accessible from other modules that import this file.
// / 此 函数 is marked pub 到 be accessible 从 other modules 该 导入 此 文件.
pub fn add(a: i32, b: i32) i32 {
    return a + b;
}

// / Multiplies two 32-bit signed integers and returns their product.
// / Multiplies 两个 32-bit signed 整数 和 返回 their product.
// / This function is marked pub to be accessible from other modules that import this file.
// / 此 函数 is marked pub 到 be accessible 从 other modules 该 导入 此 文件.
pub fn multiply(a: i32, b: i32) i32 {
    return a * b;
}

