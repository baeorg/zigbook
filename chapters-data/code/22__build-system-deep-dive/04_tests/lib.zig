//  Computes the factorial of a non-negative integer using recursion.
//  使用递归计算非负整数的阶乘。
//  The factorial of n (denoted as n!) is the product of all positive integers less than or equal to n.
//  n 的阶乘（表示为 n!）是所有小于或等于 n 的正整数的乘积。
//  Base case: factorial(0) = factorial(1) = 1
//  基本情况：阶乘(0) = 阶乘(1) = 1
//  Recursive case: factorial(n) = n * factorial(n-1)
//  递归情况：阶乘(n) = n * 阶乘(n-1)
pub fn factorial(n: u32) u32 {
    // Base case: 0! and 1! both equal 1
    // 基本情况：0! 和 1! 都等于 1
    if (n <= 1) return 1;
    // Recursive case: multiply n by factorial of (n-1)
    // 递归情况：将 n 乘以 (n-1) 的阶乘
    return n * factorial(n - 1);
}

// Test: Verify that the factorial of 0 returns 1 (base case)
// 测试：验证 0 的阶乘返回 1（基本情况）
test "factorial of 0 is 1" {
    const std = @import("std");
    try std.testing.expectEqual(@as(u32, 1), factorial(0));
}

// Test: Verify that the factorial of 5 returns 120 (5! = 5*4*3*2*1 = 120)
// 测试：验证 5 的阶乘返回 120 (5! = 5*4*3*2*1 = 120)
test "factorial of 5 is 120" {
    const std = @import("std");
    try std.testing.expectEqual(@as(u32, 120), factorial(5));
}

// Test: Verify that the factorial of 1 returns 1 (base case)
// 测试：验证 1 的阶乘返回 1（基本情况）
test "factorial of 1 is 1" {
    const std = @import("std");
    try std.testing.expectEqual(@as(u32, 1), factorial(1));
}
