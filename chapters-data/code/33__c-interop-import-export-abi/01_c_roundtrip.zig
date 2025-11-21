// 导入Zig标准库以获取基本功能
const std = @import("std");

// 使用@cImport导入C头文件以与C代码互操作
// 这会创建一个包含"bridge.h"中所有声明的命名空间'c'
const c = @cImport({
    @cInclude("bridge.h");
});

// 导出具有C调用约定的Zig函数，以便可以从C调用
// 'export'关键字使此函数对C代码可见
// callconv(.c)确保它使用平台的C ABI进行参数传递和栈管理
export fn zig_add(a: c_int, b: c_int) callconv(.c) c_int {
    return a + b;
}

pub fn main() !void {
    // 为stdout创建固定大小的缓冲区以避免堆分配
    var stdout_buffer: [128]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const out = &stdout_writer.interface;

    // 调用导入头文件中的C函数c_mul
    // 这演示了Zig无缝调用C代码
    const mul = c.c_mul(6, 7);

    // 调用内部回调我们导出的zig_add函数的C函数
    // 这演示了往返：Zig -> C -> Zig
    const sum = c.call_zig_add(19, 23);

    // 打印来自C乘法函数的结果
    try out.print("c_mul(6, 7) = {d}\n", .{mul});

    // 打印来自调用我们Zig函数的C函数的结果
    try out.print("call_zig_add(19, 23) = {d}\n", .{sum});

    // 刷新缓冲输出以确保所有数据被写入
    try out.flush();
}
