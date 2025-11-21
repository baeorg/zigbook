// 此文件演示Zig的内联语义和编译时执行特性。
// 它展示了`inline`关键字和`@call`内置函数如何控制
// 函数在编译时与运行时的评估时机和方式。

const std = @import("std");

// 使用递归计算第n个斐波那契数。
// `inline`关键字强制此函数在所有调用点被内联，
// 而`comptime n`参数确保值可以在编译时计算。
// 这种组合允许结果作为编译时常量可用。
inline fn fib(comptime n: usize) usize {
    return if (n <= 1) n else fib(n - 1) + fib(n - 2);
}

// 使用递归计算n的阶乘。
// 与`fib`不同，此函数未标记为`inline`，因此编译器
// 根据优化启发式算法决定是否内联它。
// 它可以在编译时或运行时调用。
fn factorial(n: usize) usize {
    return if (n <= 1) 1 else n * factorial(n - 1);
}

// 演示具有comptime参数的inline函数
// 将编译时执行传播到其调用点。
// 整个计算在comptime块内的编译时发生。
test "inline fibonacci propagates comptime" {
    comptime {
        const value = fib(10);
        try std.testing.expectEqual(@as(usize, 55), value);
    }
}

// 演示带有`.compile_time`修饰符的`@call`内置函数。
// 这强制函数调用在编译时评估，
// 尽管`factorial`未标记为`inline`且接受非comptime参数。
test "@call compile_time modifier" {
    const result = @call(.compile_time, factorial, .{5});
    try std.testing.expectEqual(@as(usize, 120), result);
}

// 验证非内联函数仍可在运行时调用。
// 输入是运行时值，因此计算在执行期间发生。
test "runtime factorial still works" {
    const input: usize = 6;
    const value = factorial(input);
    try std.testing.expectEqual(@as(usize, 720), value);
}
