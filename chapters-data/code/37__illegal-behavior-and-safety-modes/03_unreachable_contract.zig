// 此文件演示Zig中不同的安全模式以及如何处理
// 具有不同运行时检查级别的转换。

const std = @import("std");

/// 在不进行运行时安全检查的情况下将ASCII数字字符转换为其数值。
/// 此函数使用断言记录前置条件，输入必须是
/// 有效的ASCII数字字符（'0'-'9'）。@setRuntimeSafety(false)指令禁用
/// 减法和转换操作的运行时整数溢出检查。
///
/// 前置条件：字节必须在['0', '9']范围内
/// 返回：数值（0-9）作为u4
pub fn asciiDigitToValueUnchecked(byte: u8) u4 {
    // 断言记录约定：调用者必须提供有效的ASCII数字
    std.debug.assert(byte >= '0' and byte <= '9');

    // 禁用运行时安全的代码块，用于性能关键路径
    return blk: {
        // 禁用此转换的运行时溢出/下溢检查
        @setRuntimeSafety(false);
        // 安全的转换，因为前置条件保证结果适合u4（0-9）
        break :blk @intCast(byte - '0');
    };
}

/// 将ASCII数字字符转换为其数值，带错误处理。
/// 此函数在运行时验证输入，如果
/// 字节不是有效的ASCII数字，则返回错误，使其可以安全用于不受信任的输入。
///
/// 返回：数值（0-9）作为u4，如果无效则返回error.InvalidDigit
pub fn asciiDigitToValue(byte: u8) !u4 {
    // 验证输入在有效的ASCII数字范围内
    if (byte < '0' or byte > '9') return error.InvalidDigit;
    // 安全转换：验证确保结果在0-9范围内
    return @intCast(byte - '0');
}

// 验证未检查的转换对所有有效输入产生正确结果。
// 测试所有ASCII数字以确保基于断言的函数保持正确性
// 即使在内部禁用运行时安全。
test "assert-backed conversion stays safe across modes" {
    // 在编译时迭代所有有效的ASCII数字字符
    inline for ("0123456789") |ch| {
        // 验证未检查函数产生与直接转换相同的结果
        try std.testing.expectEqual(@as(u4, @intCast(ch - '0')), asciiDigitToValueUnchecked(ch));
    }
}

// 验证返回错误的转换正确拒绝无效输入。
// 确保错误路径正确工作并提供有意义的诊断。
test "error path preserves diagnosability" {
    // 验证非数字字符返回预期错误
    try std.testing.expectError(error.InvalidDigit, asciiDigitToValue('z'));
}
