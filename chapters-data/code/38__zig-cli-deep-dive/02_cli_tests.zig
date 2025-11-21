const std = @import("std");

// / Calculates the sum of all integers in the provided slice.
// / 计算提供切片中所有整数的和。
// / Returns 0 for an empty slice.
// / 对空切片返回 0。
fn sum(values: []const i32) i32 {
    var total: i32 = 0;
    // Accumulate all values in the slice
    // 累加切片中的所有值
    for (values) |value| total += value;
    return total;
}

// / Calculates the product of all integers in the provided slice.
// / 计算提供切片中所有整数的乘积。
// / Returns 1 for an empty slice (multiplicative identity).
// / 对空切片返回 1（乘法单位元）。
fn product(values: []const i32) i32 {
    var total: i32 = 1;
    // Multiply each value with the running total
    // 将每个值与运行总数相乘
    for (values) |value|
        total *= value;
    return total;
}

// Verifies that sum correctly adds positive integers
// 验证sum函数正确计算正整数的和
test "sum-of-three" {
    try std.testing.expectEqual(@as(i32, 42), sum(&.{ 20, 10, 12 }));
}

// Verifies that sum handles mixed positive and negative integers correctly
// 验证sum函数正确处理正负整数混合
test "sum-mixed-signs" {
    try std.testing.expectEqual(@as(i32, -1), sum(&.{ 4, -3, -2 }));
}

// Verifies that product correctly multiplies positive integers
// 验证product函数正确计算正整数的乘积
test "product-positive" {
    try std.testing.expectEqual(@as(i32, 120), product(&.{ 2, 3, 4, 5 }));
}

// Verifies that product correctly handles negative integers,
// 验证product函数正确处理负整数，
// resulting in a negative product when an odd number of negatives are present
// 当存在奇数个负数时结果为负乘积
test "product-negative" {
    try std.testing.expectEqual(@as(i32, -18), product(&.{ 3, -3, 2 }));
}
