const std = @import("std");

// / Calculates the sum of all integers in the provided slice.
// / Calculates sum 的 所有 整数 在 provided 切片.
// / Returns 0 for an empty slice.
// / 返回 0 用于 一个 空 切片.
fn sum(values: []const i32) i32 {
    var total: i32 = 0;
    // Accumulate all values in the slice
    // Accumulate 所有 值 在 切片
    for (values) |value| total += value;
    return total;
}

// / Calculates the product of all integers in the provided slice.
// / Calculates product 的 所有 整数 在 provided 切片.
// / Returns 1 for an empty slice (multiplicative identity).
// / 返回 1 用于 一个 空 切片 (multiplicative identity).
fn product(values: []const i32) i32 {
    var total: i32 = 1;
    // Multiply each value with the running total
    // Multiply 每个 值 使用 running total
    for (values) |value|
        total *= value;
    return total;
}

// Verifies that sum correctly adds positive integers
// Verifies 该 sum correctly adds 正数 整数
test "sum-of-three" {
    try std.testing.expectEqual(@as(i32, 42), sum(&.{ 20, 10, 12 }));
}

// Verifies that sum handles mixed positive and negative integers correctly
// Verifies 该 sum handles mixed 正数 和 负数 整数 correctly
test "sum-mixed-signs" {
    try std.testing.expectEqual(@as(i32, -1), sum(&.{ 4, -3, -2 }));
}

// Verifies that product correctly multiplies positive integers
// Verifies 该 product correctly multiplies 正数 整数
test "product-positive" {
    try std.testing.expectEqual(@as(i32, 120), product(&.{ 2, 3, 4, 5 }));
}

// Verifies that product correctly handles negative integers,
// Verifies 该 product correctly handles 负数 整数,
// resulting in a negative product when an odd number of negatives are present
// resulting 在 一个 负数 product 当 一个 odd 数字 的 negatives are 存在
test "product-negative" {
    try std.testing.expectEqual(@as(i32, -18), product(&.{ 3, -3, 2 }));
}
