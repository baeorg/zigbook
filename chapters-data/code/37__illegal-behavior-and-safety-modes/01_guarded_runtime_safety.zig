const std = @import("std");

// / Performs addition with overflow detection and saturation.
// / Performs addition 使用 overflow detection 和 saturation.
// / If overflow occurs, returns the maximum u8 value instead of wrapping.
// / 如果 overflow occurs, 返回 maximum u8 值 而非 wrapping.
// / Uses @setRuntimeSafety(false) in the non-overflow path for performance.
// / 使用 @setRuntimeSafety(false) 在 non-overflow 路径 用于 performance.
fn guardedUncheckedAdd(a: u8, b: u8) u8 {
    // Check if addition would overflow using builtin overflow detection
    // 检查 如果 addition would overflow 使用 内置 overflow detection
    const sum = @addWithOverflow(a, b);
    const overflow = sum[1] == 1;
    // Saturate to max value on overflow
    // Saturate 到 max 值 在 overflow
    if (overflow) return std.math.maxInt(u8);

    // Safe path: disable runtime safety checks for this addition
    // 安全 路径: disable runtime safety checks 用于 此 addition
    // since we've already verified no overflow will occur
    // since we've already verified 不 overflow will occur
    return blk: {
        @setRuntimeSafety(false);
        break :blk a + b;
    };
}

/// Performs addition without runtime safety checks.
// / This allows the operation to wrap on overflow (undefined behavior in safe mode).
// / 此 allows operation 到 wrap 在 overflow (undefined behavior 在 安全 模式).
// / Demonstrates completely disabling safety for a function scope.
// / 演示 completely disabling safety 用于 一个 函数 scope.
fn wrappingAddUnsafe(a: u8, b: u8) u8 {
    // Disable all runtime safety checks for this entire function
    // Disable 所有 runtime safety checks 用于 此 entire 函数
    @setRuntimeSafety(false);
    return a + b;
}

// Verifies that guardedUncheckedAdd correctly handles both normal addition
// Verifies 该 guardedUncheckedAdd correctly handles both normal addition
// and overflow saturation scenarios.
// 和 overflow saturation scenarios.
test "guarded unchecked addition saturates on overflow" {
    // Normal case: 120 + 80 = 200 (no overflow)
    // Normal case: 120 + 80 = 200 (不 overflow)
    try std.testing.expectEqual(@as(u8, 200), guardedUncheckedAdd(120, 80));
    // Overflow case: 240 + 30 = 270 > 255, should saturate to 255
    // Overflow case: 240 + 30 = 270 > 255, should saturate 到 255
    try std.testing.expectEqual(std.math.maxInt(u8), guardedUncheckedAdd(240, 30));
}

// Demonstrates that wrappingAddUnsafe produces the same wrapped result
// 演示 该 wrappingAddUnsafe produces same wrapped result
// as @addWithOverflow when overflow occurs.
// 作为 @addWithOverflow 当 overflow occurs.
test "wrapping addition mirrors overflow tuple" {
    // @addWithOverflow returns [wrapped_result, overflow_bit]
    // @addWithOverflow 返回 [wrapped_result, overflow_bit]
    const sum = @addWithOverflow(@as(u8, 250), @as(u8, 10));
    // Verify overflow occurred (250 + 10 = 260 > 255)
    try std.testing.expect(sum[1] == 1);
    // Verify wrapped result matches unchecked addition (260 % 256 = 4)
    try std.testing.expectEqual(sum[0], wrappingAddUnsafe(250, 10));
}
