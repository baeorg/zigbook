
// This file demonstrates Zig's inline semantics and compile-time execution features.
// 此 文件 演示 Zig's inline 语义 和 编译-time execution features.
// It shows how the `inline` keyword and `@call` builtin can control when and how
// It shows how `inline` keyword 和 `@call` 内置 can control 当 和 how
// functions are evaluated at compile-time versus runtime.
// 函数 are evaluated 在 编译-time versus runtime.

const std = @import("std");

// / Computes the nth Fibonacci number using recursion.
// / Computes nth Fibonacci 数字 使用 recursion.
// / The `inline` keyword forces this function to be inlined at all call sites,
// / `inline` keyword forces 此 函数 到 be inlined 在 所有 call sites,
// / and the `comptime n` parameter ensures the value can be computed at compile-time.
// / 和 `comptime n` parameter 确保 值 can be computed 在 编译-time.
// / This combination allows the result to be available as a compile-time constant.
// / 此 combination allows result 到 be available 作为 一个 编译-time constant.
inline fn fib(comptime n: usize) usize {
    return if (n <= 1) n else fib(n - 1) + fib(n - 2);
}

// / Computes the factorial of n using recursion.
// / Computes factorial 的 n 使用 recursion.
// / Unlike `fib`, this function is not marked `inline`, so the compiler
// / Unlike `fib`, 此 函数 is 不 marked `inline`, so compiler
// / decides whether to inline it based on optimization heuristics.
// / decides whether 到 inline it 基于 optimization heuristics.
// / It can be called at either compile-time or runtime.
// / It can be called 在 either 编译-time 或 runtime.
fn factorial(n: usize) usize {
    return if (n <= 1) 1 else n * factorial(n - 1);
}

// Demonstrates that an inline function with comptime parameters
// 演示 该 一个 inline 函数 使用 comptime parameters
// propagates compile-time execution to its call sites.
// propagates 编译-time execution 到 its call sites.
// The entire computation happens at compile-time within the comptime block.
// entire computation happens 在 编译-time within comptime block.
test "inline fibonacci propagates comptime" {
    comptime {
        const value = fib(10);
        try std.testing.expectEqual(@as(usize, 55), value);
    }
}

// Demonstrates the `@call` builtin with `.compile_time` modifier.
// 演示 `@call` 内置 使用 `.compile_time` modifier.
// This forces the function call to be evaluated at compile-time,
// 此 forces 函数 call 到 be evaluated 在 编译-time,
// even though `factorial` is not marked `inline` and takes non-comptime parameters.
// even though `factorial` is 不 marked `inline` 和 takes non-comptime parameters.
test "@call compile_time modifier" {
    const result = @call(.compile_time, factorial, .{5});
    try std.testing.expectEqual(@as(usize, 120), result);
}

// Verifies that a non-inline function can still be called at runtime.
// Verifies 该 一个 non-inline 函数 can still be called 在 runtime.
// The input is a runtime value, so the computation happens during execution.
// 输入 is 一个 runtime 值, so computation happens during execution.
test "runtime factorial still works" {
    const input: usize = 6;
    const value = factorial(input);
    try std.testing.expectEqual(@as(usize, 720), value);
}
