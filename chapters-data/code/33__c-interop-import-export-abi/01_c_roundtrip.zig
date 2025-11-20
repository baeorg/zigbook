// Import the Zig standard library for basic functionality
// 导入 Zig 标准库 用于 basic functionality
const std = @import("std");

// Import C header file using @cImport to interoperate with C code
// 导入 C header 文件 使用 @cImport 到 interoperate 使用 C 代码
// This creates a namespace 'c' containing all declarations from "bridge.h"
// 此 creates 一个 namespace 'c' containing 所有 declarations 从 "bridge.h"
const c = @cImport({
    @cInclude("bridge.h");
});

// Export a Zig function with C calling convention so it can be called from C
// Export 一个 Zig 函数 使用 C calling convention so it can be called 从 C
// The 'export' keyword makes this function visible to C code
// 'export' keyword makes 此 函数 visible 到 C 代码
// callconv(.c) ensures it uses the platform's C ABI for parameter passing and stack management
// callconv(.c) 确保 it 使用 platform's C ABI 用于 parameter passing 和 栈 management
export fn zig_add(a: c_int, b: c_int) callconv(.c) c_int {
    return a + b;
}

pub fn main() !void {
    // Create a fixed-size buffer for stdout to avoid heap allocations
    // 创建一个 固定大小缓冲区 用于 stdout 到 avoid 堆 allocations
    var stdout_buffer: [128]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const out = &stdout_writer.interface;

    // Call C function c_mul from the imported header
    // Call C 函数 c_mul 从 imported header
    // This demonstrates Zig calling into C code seamlessly
    // 此 演示 Zig calling into C 代码 seamlessly
    const mul = c.c_mul(6, 7);
    
    // Call C function that internally calls back into our exported zig_add function
    // Call C 函数 该 internally calls back into our exported zig_add 函数
    // This demonstrates the round-trip: Zig -> C -> Zig
    // 此 演示 round-trip: Zig -> C -> Zig
    const sum = c.call_zig_add(19, 23);

    // Print the result from the C multiplication function
    // 打印 result 从 C multiplication 函数
    try out.print("c_mul(6, 7) = {d}\n", .{mul});
    
    // Print the result from the C function that called our Zig function
    // 打印 result 从 C 函数 该 called our Zig 函数
    try out.print("call_zig_add(19, 23) = {d}\n", .{sum});
    
    // Flush the buffered output to ensure all data is written
    // 刷新 缓冲 输出 到 确保 所有 数据 is written
    try out.flush();
}
