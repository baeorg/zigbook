
// This file demonstrates different safety modes in Zig and how to handle
// 此 文件 演示 different safety modes 在 Zig 和 how 到 处理
// conversions with varying levels of runtime checking.
// conversions 使用 varying levels 的 runtime checking.

const std = @import("std");

// / Converts an ASCII digit character to its numeric value without runtime safety checks.
// / Converts 一个 ASCII digit character 到 its numeric 值 without runtime safety checks.
// / This function uses an assert to document the precondition that the input must be
// / 此 函数 使用 一个 assert 到 document precondition 该 输入 must be
// / a valid ASCII digit ('0'-'9'). The @setRuntimeSafety(false) directive disables
// / 一个 valid ASCII digit ('0'-'9'). @setRuntimeSafety(false) directive disables
// / runtime integer overflow checks for the subtraction and cast operations.
// / runtime integer overflow checks 用于 subtraction 和 cast operations.
/// 
// / Precondition: byte must be in the range ['0', '9']
// / Precondition: byte must be 在 range ['0', '9']
// / Returns: The numeric value (0-9) as a u4
// / 返回: numeric 值 (0-9) 作为 一个 u4
pub fn asciiDigitToValueUnchecked(byte: u8) u4 {
    // Assert documents the contract: caller must provide a valid ASCII digit
    // Assert documents contract: caller must provide 一个 valid ASCII digit
    std.debug.assert(byte >= '0' and byte <= '9');
    
    // Block with runtime safety disabled for performance-critical paths
    // Block 使用 runtime safety disabled 用于 performance-critical 路径
    return blk: {
        // Disable runtime overflow/underflow checks for this conversion
        // Disable runtime overflow/underflow checks 用于 此 conversion
        @setRuntimeSafety(false);
        // Safe cast because precondition guarantees result fits in u4 (0-9)
        // 安全 cast because precondition guarantees result fits 在 u4 (0-9)
        break :blk @intCast(byte - '0');
    };
}

// / Converts an ASCII digit character to its numeric value with error handling.
// / Converts 一个 ASCII digit character 到 its numeric 值 使用 错误处理.
// / This function validates the input at runtime and returns an error if the
// / 此 函数 validates 输入 在 runtime 和 返回一个错误 如果
// / byte is not a valid ASCII digit, making it safe to use with untrusted input.
// / byte is 不 一个 valid ASCII digit, making it 安全 到 use 使用 untrusted 输入.
/// 
// / Returns: The numeric value (0-9) as a u4, or error.InvalidDigit if invalid
// / 返回: numeric 值 (0-9) 作为 一个 u4, 或 错误.InvalidDigit 如果 无效
pub fn asciiDigitToValue(byte: u8) !u4 {
    // Validate input is within valid ASCII digit range
    // 验证 输入 is within valid ASCII digit range
    if (byte < '0' or byte > '9') return error.InvalidDigit;
    // Safe cast: validation ensures result is in range 0-9
    // 安全 cast: validation 确保 result is 在 range 0-9
    return @intCast(byte - '0');
}

// Verifies that the unchecked conversion produces correct results for all valid inputs.
// Verifies 该 unchecked conversion produces correct results 用于 所有 valid inputs.
// Tests all ASCII digits to ensure the assert-backed function maintains correctness
// Tests 所有 ASCII digits 到 确保 assert-backed 函数 maintains correctness
// even when runtime safety is disabled internally.
// even 当 runtime safety is disabled internally.
test "assert-backed conversion stays safe across modes" {
    // Iterate over all valid ASCII digit characters at compile time
    // 迭代 over 所有 valid ASCII digit characters 在 编译时
    inline for ("0123456789") |ch| {
        // Verify unchecked function produces same result as direct conversion
        // Verify unchecked 函数 produces same result 作为 direct conversion
        try std.testing.expectEqual(@as(u4, @intCast(ch - '0')), asciiDigitToValueUnchecked(ch));
    }
}

// Verifies that the error-returning conversion properly rejects invalid input.
// Verifies 该 错误-returning conversion properly rejects 无效 输入.
// Ensures that error handling path works correctly and provides meaningful diagnostics.
// 确保 该 错误处理 路径 works correctly 和 provides meaningful diagnostics.
test "error path preserves diagnosability" {
    // Verify that non-digit characters return the expected error
    // Verify 该 non-digit characters 返回 expected 错误
    try std.testing.expectError(error.InvalidDigit, asciiDigitToValue('z'));
}
