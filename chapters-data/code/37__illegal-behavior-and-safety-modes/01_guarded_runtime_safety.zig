const std = @import("std");

/// 执行带溢出检测和饱和的加法。
/// 如果发生溢出，返回最大值u8而不是环绕。
/// 在非溢出路径中使用@setRuntimeSafety(false)以提高性能。
fn guardedUncheckedAdd(a: u8, b: u8) u8 {
    // 使用内置溢出检测检查加法是否会溢出
    const sum = @addWithOverflow(a, b);
    const overflow = sum[1] == 1;
    // 溢出时饱和到最大值
    if (overflow) return std.math.maxInt(u8);

    // 安全路径：为此加法禁用运行时安全检查
    // 因为我们已经验证不会发生溢出
    return blk: {
        @setRuntimeSafety(false);
        break :blk a + b;
    };
}

/// 执行不带运行时安全检查的加法。
/// 这允许操作在溢出时环绕（安全模式中的未定义行为）。
/// 演示完全禁用函数作用域的安全性。
fn wrappingAddUnsafe(a: u8, b: u8) u8 {
    // 禁用整个函数的所有运行时安全检查
    @setRuntimeSafety(false);
    return a + b;
}

// 验证guardedUncheckedAdd正确处理正常加法和溢出饱和场景。
test "guarded unchecked addition saturates on overflow" {
    // 正常情况：120 + 80 = 200（无溢出）
    try std.testing.expectEqual(@as(u8, 200), guardedUncheckedAdd(120, 80));
    // 溢出情况：240 + 30 = 270 > 255，应饱和到255
    try std.testing.expectEqual(std.math.maxInt(u8), guardedUncheckedAdd(240, 30));
}

// 演示wrappingAddUnsafe在溢出时产生与@addWithOverflow相同的环绕结果。
test "wrapping addition mirrors overflow tuple" {
    // @addWithOverflow返回[wrapped_result, overflow_bit]
    const sum = @addWithOverflow(@as(u8, 250), @as(u8, 10));
    // 验证发生了溢出（250 + 10 = 260 > 255）
    try std.testing.expect(sum[1] == 1);
    // 验证环绕结果与未检查加法匹配（260 % 256 = 4）
    try std.testing.expectEqual(sum[0], wrappingAddUnsafe(250, 10));
}
