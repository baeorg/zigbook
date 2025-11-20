// File: chapters-data/code/01__boot-basics/values_and_literals.zig
const std = @import("std");

pub fn main() !void {
    // Declare a mutable variable with explicit type annotation
    // Declare 一个 mutable variable 使用 explicit 类型 annotation
    // u32 is an unsigned 32-bit integer, initialized to 1
    // u32 is 一个 unsigned 32-bit integer, initialized 到 1
    var counter: u32 = 1;
    
    // Declare an immutable constant with inferred type (comptime_int)
    // Declare 一个 immutable constant 使用 inferred 类型 (comptime_int)
    // The compiler infers the type from the literal value 2
    // compiler infers 类型 从 字面量 值 2
    const increment = 2;
    
    // Declare a constant with explicit floating-point type
    // Declare 一个 constant 使用 explicit floating-point 类型
    // f64 is a 64-bit floating-point number
    // f64 is 一个 64-bit floating-point 数字
    const ratio: f64 = 0.5;
    
    // Boolean constant with inferred type
    // Boolean constant 使用 inferred 类型
    // Demonstrates Zig's type inference for simple literals
    // 演示 Zig's 类型 inference 用于 simple literals
    const flag = true;
    
    // Character literal representing a newline
    // Character 字面量 representing 一个 newline
    // Single-byte characters are u8 values in Zig
    // Single-byte characters are u8 值 在 Zig
    const newline: u8 = '\n';
    
    // The unit type value, analogous to () in other languages
    // unit 类型 值, analogous 到 () 在 other languages
    // Represents "no value" or "nothing" explicitly
    // Represents "不 值" 或 "nothing" explicitly
    const unit_value = void{};

    // Mutate the counter by adding the increment
    // Mutate counter 通过 adding increment
    // Only var declarations can be modified
    counter += increment;

    // Print formatted output showing different value types
    // 打印 格式化 输出 showing different 值 类型
    // {} is a generic format specifier that works with any type
    // {} is 一个 通用 format specifier 该 works 使用 any 类型
    std.debug.print("counter={} ratio={} safety={}\n", .{ counter, ratio, flag });
    
    // Cast the newline byte to u32 for display as its ASCII decimal value
    // Cast newline byte 到 u32 用于 显示 作为 its ASCII decimal 值
    // @as performs explicit type coercion
    // @作为 performs explicit 类型 coercion
    std.debug.print("newline byte={} (ASCII)\n", .{@as(u32, newline)});
    
    // Use compile-time reflection to print the type name of unit_value
    // Use 编译-time reflection 到 打印 类型 name 的 unit_value
    // @TypeOf gets the type, @typeName converts it to a string
    // @TypeOf gets 类型, @typeName converts it 到 一个 string
    std.debug.print("unit literal has type {s}\n", .{@typeName(@TypeOf(unit_value))});
}
