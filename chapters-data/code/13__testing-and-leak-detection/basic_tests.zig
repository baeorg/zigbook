const std = @import("std");

// / Performs exact integer division, returning an error if the divisor is zero.
// / Performs exact integer division, returning 一个 错误 如果 divisor is 零.
// / This function demonstrates error handling in a testable way.
// / 此 函数 演示 错误处理 在 一个 testable way.
fn divExact(a: i32, b: i32) !i32 {
    // Guard clause: check for division by zero before attempting division
    // Guard clause: 检查 division 通过 零 before attempting division
    if (b == 0) return error.DivideByZero;
    // Safe to divide: use @divTrunc for truncating integer division
    // 安全 到 divide: use @divTrunc 用于 truncating integer division
    return @divTrunc(a, b);
}

test "boolean and equality expectations" {
    // Test basic boolean expression using expect
    // Test basic boolean expression 使用 expect
    // expect() returns an error if the condition is false
    // expect() 返回一个错误 如果 condition is false
    try std.testing.expect(2 + 2 == 4);
    
    // Test type-safe equality with expectEqual
    // Test 类型-安全 equality 使用 expectEqual
    // Both arguments must be the same type; here we explicitly cast to u8
    // Both arguments must be same 类型; here we explicitly cast 到 u8
    try std.testing.expectEqual(@as(u8, 42), @as(u8, 42));
}

test "string equality (bytes)" {
    // Define expected string as a slice of const bytes
    // 定义 expected string 作为 一个 切片 的 const bytes
    const expected: []const u8 = "hello";
    
    // Create actual string via compile-time concatenation
    // 创建 actual string via 编译-time concatenation
    // The ++ operator concatenates string literals at compile time
    // ++ operator concatenates string literals 在 编译时
    const actual: []const u8 = "he" ++ "llo";
    
    // Use expectEqualStrings for slice comparison
    // Use expectEqualStrings 用于 切片 comparison
    // This compares the content of the slices, not just the pointer addresses
    // 此 compares content 的 slices, 不 just pointer addresses
    try std.testing.expectEqualStrings(expected, actual);
}

test "expecting an error" {
    // Test that divExact returns the expected error when dividing by zero
    // Test 该 divExact 返回 expected 错误 当 dividing 通过 零
    // expectError() succeeds if the function returns the specified error
    // expectError() succeeds 如果 函数 返回 specified 错误
    try std.testing.expectError(error.DivideByZero, divExact(1, 0));
    
    // Test successful division path
    // Test successful division 路径
    // We use 'try' to unwrap the success value, then expectEqual to verify it
    // We use 'try' 到 解包 成功 值, 那么 expectEqual 到 verify it
    // If divExact returns an error here, the test will fail
    // 如果 divExact 返回一个错误 here, test will fail
    try std.testing.expectEqual(@as(i32, 3), try divExact(9, 3));
}
