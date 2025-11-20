
// Import the Zig standard library for basic functionality
// 导入 Zig 标准库 用于 basic functionality
const std = @import("std");

// Import C header file using @cImport to interoperate with C code
// 导入 C header 文件 使用 @cImport 到 interoperate 使用 C 代码
// This creates a namespace 'c' containing all declarations from "abi.h"
// 此 creates 一个 namespace 'c' containing 所有 declarations 从 "abi.h"
const c = @cImport({
    @cInclude("abi.h");
});

// Define a Zig struct with 'extern' keyword to match C ABI layout
// 定义一个 Zig struct 使用 'extern' keyword 到 match C ABI layout
// The 'extern' keyword ensures the struct uses C-compatible memory layout
// 'extern' keyword 确保 struct 使用 C-compatible 内存 layout
// without Zig's automatic padding optimizations
const SensorSample = extern struct {
    temperature_c: f32,  // Temperature reading in Celsius (32-bit float)
    status_bits: u16,    // Status flags packed into 16 bits
    port_id: u8,         // Port identifier (8-bit unsigned)
    reserved: u8 = 0,    // Reserved byte for alignment/future use, default to 0
};

// Convert a C struct to its Zig equivalent using pointer casting
// Convert 一个 C struct 到 its Zig equivalent 使用 pointer casting
// This demonstrates type-punning between C and Zig representations
// 此 演示 类型-punning between C 和 Zig representations
// @ptrCast reinterprets the memory layout without copying data
// @ptrCast reinterprets 内存 layout without copying 数据
fn fromC(sample: c.struct_SensorSample) SensorSample {
    return @as(*const SensorSample, @ptrCast(&sample)).*;
}

pub fn main() !void {
    // Create a fixed-size buffer for stdout to avoid allocations
    // 创建一个 固定大小缓冲区 用于 stdout 到 avoid allocations
    var stdout_buffer: [256]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const out = &stdout_writer.interface;

    // Print size comparison between C and Zig struct representations
    // 打印 size comparison between C 和 Zig struct representations
    // Both should be identical due to 'extern' struct attribute
    // Both should be identical 由于 'extern' struct attribute
    try out.print("sizeof(C struct) = {d}\n", .{@sizeOf(c.struct_SensorSample)});
    try out.print("sizeof(Zig extern struct) = {d}\n", .{@sizeOf(SensorSample)});

    // Call C functions to create sensor samples with specific values
    // Call C 函数 到 创建 sensor 样本 使用 specific 值
    const left = c.make_sensor_sample(42.5, 0x0102, 7);
    const right = c.make_sensor_sample(38.0, 0x0004, 9);
    
    // Call C function that operates on C structs and returns a computed value
    // Call C 函数 该 operates 在 C structs 和 返回 一个 computed 值
    const total = c.combined_voltage(left, right);

    // Convert C structs to Zig structs for idiomatic Zig access
    // Convert C structs 到 Zig structs 用于 idiomatic Zig access
    const zig_left = fromC(left);
    const zig_right = fromC(right);

    // Print sensor data from the left port with formatted output
    // 打印 sensor 数据 从 left port 使用 格式化 输出
    try out.print(
        "left port {d}: {d} status bits, {d:.2} °C\n",
        .{ zig_left.port_id, zig_left.status_bits, zig_left.temperature_c },
    );
    
    // Print sensor data from the right port with formatted output
    // 打印 sensor 数据 从 right port 使用 格式化 输出
    try out.print(
        "right port {d}: {d} status bits, {d:.2} °C\n",
        .{ zig_right.port_id, zig_right.status_bits, zig_right.temperature_c },
    );
    
    // Print the combined voltage result computed by C function
    // 打印 combined voltage result computed 通过 C 函数
    try out.print("combined_voltage = {d:.3}\n", .{total});
    
    // Flush the buffered output to ensure all data is written
    // 刷新 缓冲 输出 到 确保 所有 数据 is written
    try out.flush();
}
