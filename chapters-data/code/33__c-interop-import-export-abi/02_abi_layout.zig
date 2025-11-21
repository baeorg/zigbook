// 导入Zig标准库以获取基本功能
const std = @import("std");

// 使用@cImport导入C头文件以与C代码互操作
// 这会创建一个包含"abi.h"中所有声明的命名空间'c'
const c = @cImport({
    @cInclude("abi.h");
});

// 使用'extern'关键字定义Zig结构以匹配C ABI布局
// 'extern'关键字确保结构使用C兼容的内存布局
// 而不进行Zig的自动填充优化
const SensorSample = extern struct {
    temperature_c: f32,  // 摄氏温度读数（32位浮点）
    status_bits: u16,    // 状态标志打包为16位
    port_id: u8,         // 端口标识符（8位无符号）
    reserved: u8 = 0,    // 用于对齐/未来保留的字节，默认为0
};

// 使用指针转换将C结构转换为其Zig等效结构
// 这演示了C和Zig表示之间的类型转换
// @ptrCast在不复制数据的情况下重新解释内存布局
fn fromC(sample: c.struct_SensorSample) SensorSample {
    return @as(*const SensorSample, @ptrCast(&sample)).*;
}

pub fn main() !void {
    // 为stdout创建固定大小的缓冲区以避免分配
    var stdout_buffer: [256]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const out = &stdout_writer.interface;

    // 打印C和Zig结构表示之间的size比较
    // 由于'extern'结构属性，两者应该完全相同
    try out.print("sizeof(C struct) = {d}\n", .{@sizeOf(c.struct_SensorSample)});
    try out.print("sizeof(Zig extern struct) = {d}\n", .{@sizeOf(SensorSample)});

    // 调用C函数以创建具有特定值的传感器样本
    const left = c.make_sensor_sample(42.5, 0x0102, 7);
    const right = c.make_sensor_sample(38.0, 0x0004, 9);

    // 调用操作C结构并返回计算值的C函数
    const total = c.combined_voltage(left, right);

    // 将C结构转换为Zig结构以进行惯用Zig访问
    const zig_left = fromC(left);
    const zig_right = fromC(right);

    // 打印来自左端口的传感器数据，带格式化输出
    try out.print(
        "left port {d}: {d} status bits, {d:.2} °C\n",
        .{ zig_left.port_id, zig_left.status_bits, zig_left.temperature_c },
    );

    // 打印来自右端口的传感器数据，带格式化输出
    try out.print(
        "right port {d}: {d} status bits, {d:.2} °C\n",
        .{ zig_right.port_id, zig_right.status_bits, zig_right.temperature_c },
    );

    // 打印由C函数计算的组合电压结果
    try out.print("combined_voltage = {d:.3}\n", .{total});

    // 刷新缓冲输出以确保所有数据被写入
    try out.flush();
}
