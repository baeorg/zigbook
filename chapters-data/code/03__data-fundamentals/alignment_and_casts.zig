const std = @import("std");

/// 演示Zig中的内存对齐概念和各种类型转换操作
/// 本示例涵盖：
/// - 使用align()属性的内存对齐保证
/// - 使用@alignCast的指针转换和对齐调整
/// - 使用@ptrCast进行内存重新解释的类型转换
/// - 使用@bitCast的位级重新解释
/// - 使用@truncate截断整数
/// - 使用@intCast扩展整数
/// - 使用@floatCast浮点精度转换
pub fn main() !void {
    // 创建对齐到u64边界的字节数组，用小端字节初始化
    // 表示前4个字节中的0x11223344
    var raw align(@alignOf(u64)) = [_]u8{ 0x44, 0x33, 0x22, 0x11, 0, 0, 0, 0 };

    // 获取指向首字节的指针，带有显式u64对齐
    const base: *align(@alignOf(u64)) u8 = &raw[0];

    // 使用@alignCast调整对齐约束从u64到u32
    // 这是安全的，因为u64对齐（8字节）满足u32对齐（4字节）
    const aligned_bytes = @as(*align(@alignOf(u32)) const u8, @alignCast(base));

    // 将字节指针重新解释为u32指针，将4字节读取为单个整数
    const word_ptr = @as(*const u32, @ptrCast(aligned_bytes));

    // 解引用以获取32位值（小端：0x11223344）
    const number = word_ptr.*;
    std.debug.print("32-bit value = 0x{X:0>8}\n", .{number});

    // 替代方法：使用@bitCast直接重新解释前4字节
    // 这会创建一个副本，不需要指针操作
    const from_bytes = @as(u32, @bitCast(raw[0..4].*));
    std.debug.print("bitcast copy = 0x{X:0>8}\n", .{from_bytes});

    // 演示@truncate：提取最低有效8位（0x44）
    const small: u8 = @as(u8, @truncate(number));

    // 演示@intCast：将无符号u32扩展为有符号i64，无数据丢失
    const widened: i64 = @as(i64, @intCast(number));
    std.debug.print("truncate -> 0x{X:0>2}, widen -> {d}\n", .{ small, widened });

    // 演示@floatCast：将f64精度降低到f32
    // 对于无法在f32中精确表示的值，可能会导致精度损失
    const ratio64: f64 = 1.875;
    const ratio32: f32 = @as(f32, @floatCast(ratio64));
    std.debug.print("floatCast ratio -> {}\n", .{ratio32});
}
