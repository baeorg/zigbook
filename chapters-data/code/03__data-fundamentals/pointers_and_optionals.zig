const std = @import("std");

/// A simple structure representing a sensor device with a numeric reading.
/// 表示具有数值读数的传感器设备的简单结构
const Sensor = struct {
    reading: i32,
};

/// Prints a sensor's reading value to debug output.
/// 将传感器的读数值打印到调试输出
// / Takes a single pointer to a Sensor and displays its current reading.
// / Takes 一个 single pointer 到 一个 Sensor 和 displays its 当前 reading.
fn report(label: []const u8, ptr: *Sensor) void {
    std.debug.print("{s} -> reading {d}\n", .{ label, ptr.reading });
}

// / Demonstrates pointer fundamentals, optional pointers, and many-item pointers in Zig.
// / 演示 pointer fundamentals, 可选 pointers, 和 many-item pointers 在 Zig.
// / This example covers:
// / 此 示例 covers:
// / - Single-item pointers (*T) and pointer dereferencing
// / - Single-item pointers (*T) 和 pointer dereferencing
// / - Pointer aliasing and mutation through aliases
// / - Pointer aliasing 和 mutation through aliases
// / - Optional pointers (?*T) for representing nullable references
// / - 可选 pointers (?*T) 用于 representing nullable references
// / - Unwrapping optional pointers with if statements
// / - Unwrapping 可选 pointers 使用 如果 statements
// / - Many-item pointers ([*]T) for unchecked multi-element access
// / - Many-item pointers ([*]T) 用于 unchecked multi-element access
// / - Converting slices to many-item pointers via .ptr property
// / - Converting slices 到 many-item pointers via .ptr property
pub fn main() !void {
    // Create a sensor instance on the stack
    // 创建一个 sensor instance 在 栈
    var sensor = Sensor{ .reading = 41 };
    
    // Create a single-item pointer alias to the sensor
    // 创建一个 single-item pointer alias 到 sensor
    // The & operator takes the address of sensor
    // & operator takes address 的 sensor
    var alias: *Sensor = &sensor;
    
    // Modify the sensor through the pointer alias
    // Modify sensor through pointer alias
    // Zig automatically dereferences pointer fields
    alias.reading += 1;

    report("alias", alias);

    // Declare an optional pointer initialized to null
    // Declare 一个 可选 pointer initialized 到 空
    // ?*T represents a pointer that may or may not hold a valid address
    // ?*T represents 一个 pointer 该 may 或 may 不 hold 一个 valid address
    var maybe_alias: ?*Sensor = null;
    
    // Attempt to unwrap the optional pointer
    // 尝试 解包 可选 pointer
    // This branch will not execute because maybe_alias is null
    // 此 branch will 不 execute because maybe_alias is 空
    if (maybe_alias) |pointer| {
        std.debug.print("unexpected pointer: {d}\n", .{pointer.reading});
    } else {
        std.debug.print("optional pointer empty\n", .{});
    }

    // Assign a valid address to the optional pointer
    // Assign 一个 valid address 到 可选 pointer
    maybe_alias = &sensor;
    
    // Unwrap and use the optional pointer
    // 解包 和 use 可选 pointer
    // The |pointer| capture syntax extracts the non-null value
    // |pointer| 捕获 语法 extracts non-空 值
    if (maybe_alias) |pointer| {
        pointer.reading += 10;
        std.debug.print("optional pointer mutated to {d}\n", .{sensor.reading});
    }

    // Create an array and a slice view of it
    // 创建 一个 数组 和 一个 切片 view 的 it
    var samples = [_]i32{ 5, 7, 9, 11 };
    const view: []i32 = samples[0..];
    
    // Extract a many-item pointer from the slice
    // Extract 一个 many-item pointer 从 切片
    // Many-item pointers ([*]T) allow unchecked indexing without length tracking
    const many: [*]i32 = view.ptr;
    
    // Modify the underlying array through the many-item pointer
    // Modify underlying 数组 through many-item pointer
    // No bounds checking is performed at this point
    // 不 bounds checking is performed 在 此 point
    many[2] = 42;

    std.debug.print("slice view len={}\n", .{view.len});
    // Verify that the modification through many-item pointer affected the original array
    // Verify 该 modification through many-item pointer affected 原始 数组
    std.debug.print("samples[2] via many pointer = {d}\n", .{samples[2]});
}
