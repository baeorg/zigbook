const std = @import("std");

// / Demonstrates memory alignment concepts and various type casting operations in Zig.
// / 演示 内存 alignment concepts 和 various 类型 casting operations 在 Zig.
// / This example covers:
// / 此 示例 covers:
// / - Memory alignment guarantees with align() attribute
// / - 内存 alignment guarantees 使用 align() attribute
// / - Pointer casting with alignment adjustments using @alignCast
// / - Pointer casting 使用 alignment adjustments 使用 @alignCast
// / - Type punning with @ptrCast for reinterpreting memory
// / - 类型 punning 使用 @ptrCast 用于 reinterpreting 内存
// / - Bitwise reinterpretation with @bitCast
// / - Bitwise reinterpretation 使用 @bitCast
// / - Truncating integers with @truncate
// / - Truncating 整数 使用 @truncate
// / - Widening integers with @intCast
// / - Widening 整数 使用 @intCast
// / - Floating-point precision conversion with @floatCast
// / - Floating-point precision conversion 使用 @floatCast
pub fn main() !void {
    // Create a byte array aligned to u64 boundary, initialized with little-endian bytes
    // 创建一个 byte 数组 aligned 到 u64 boundary, initialized 使用 little-endian bytes
    // representing 0x11223344 in the first 4 bytes
    // representing 0x11223344 在 首先 4 bytes
    var raw align(@alignOf(u64)) = [_]u8{ 0x44, 0x33, 0x22, 0x11, 0, 0, 0, 0 };

    // Get a pointer to the first byte with explicit u64 alignment
    // 获取 一个 pointer 到 首先 byte 使用 explicit u64 alignment
    const base: *align(@alignOf(u64)) u8 = &raw[0];
    
    // Adjust alignment constraint from u64 to u32 using @alignCast
    // Adjust alignment constraint 从 u64 到 u32 使用 @alignCast
    // This is safe because u64 alignment (8 bytes) satisfies u32 alignment (4 bytes)
    // 此 is 安全 because u64 alignment (8 bytes) satisfies u32 alignment (4 bytes)
    const aligned_bytes = @as(*align(@alignOf(u32)) const u8, @alignCast(base));
    
    // Reinterpret the byte pointer as a u32 pointer to read 4 bytes as a single integer
    // Reinterpret byte pointer 作为 一个 u32 pointer 到 读取 4 bytes 作为 一个 single integer
    const word_ptr = @as(*const u32, @ptrCast(aligned_bytes));
    
    // Dereference to get the 32-bit value (little-endian: 0x11223344)
    // Dereference 到 获取 32-bit 值 (little-endian: 0x11223344)
    const number = word_ptr.*;
    std.debug.print("32-bit value = 0x{X:0>8}\n", .{number});

    // Alternative approach: directly reinterpret the first 4 bytes using @bitCast
    // Alternative approach: directly reinterpret 首先 4 bytes 使用 @bitCast
    // This creates a copy and doesn't require pointer manipulation
    // 此 creates 一个 复制 和 doesn't require pointer manipulation
    const from_bytes = @as(u32, @bitCast(raw[0..4].*));
    std.debug.print("bitcast copy = 0x{X:0>8}\n", .{from_bytes});

    // Demonstrate @truncate: extract the least significant 8 bits (0x44)
    // Demonstrate @truncate: extract least significant 8 bits (0x44)
    const small: u8 = @as(u8, @truncate(number));
    
    // Demonstrate @intCast: widen unsigned u32 to signed i64 without data loss
    // Demonstrate @intCast: widen unsigned u32 到 signed i64 without 数据 loss
    const widened: i64 = @as(i64, @intCast(number));
    std.debug.print("truncate -> 0x{X:0>2}, widen -> {d}\n", .{ small, widened });

    // Demonstrate @floatCast: reduce f64 precision to f32
    // Demonstrate @floatCast: reduce f64 precision 到 f32
    // May result in precision loss for values that cannot be exactly represented in f32
    // May result 在 precision loss 用于 值 该 cannot be exactly represented 在 f32
    const ratio64: f64 = 1.875;
    const ratio32: f32 = @as(f32, @floatCast(ratio64));
    std.debug.print("floatCast ratio -> {}\n", .{ratio32});
}
