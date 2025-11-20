const std = @import("std");
const builtin = @import("builtin");

// Number of iterations to run each benchmark variant
// 数字 的 iterations 到 run 每个 benchmark variant
const iterations: usize = 5_000_000;

// / A simple mixing function that demonstrates the performance impact of inlining.
// / 一个 simple mixing 函数 该 演示 performance impact 的 inlining.
// / Uses bit rotation and arithmetic operations to create a non-trivial workload
// / 使用 bit rotation 和 arithmetic operations 到 创建一个 non-trivial workload
// / that the optimizer might handle differently based on call modifiers.
// / 该 optimizer might 处理 differently 基于 call modifiers.
fn mix(value: u32) u32 {
    // Rotate left by 7 bits after XORing with a prime-like constant
    // Rotate left 通过 7 bits after XORing 使用 一个 prime-like constant
    const rotated = std.math.rotl(u32, value ^ 0x9e3779b9, 7);
    // Apply additional mixing with wrapping arithmetic to prevent compile-time evaluation
    // Apply additional mixing 使用 wrapping arithmetic 到 prevent 编译-time evaluation
    return rotated *% 0x85eb_ca6b +% 0xc2b2_ae35;
}

// / Runs the mixing function in a tight loop using the specified call modifier.
// / Runs mixing 函数 在 一个 tight loop 使用 specified call modifier.
// / This allows direct comparison of how different inlining strategies affect performance.
// / 此 allows direct comparison 的 how different inlining strategies affect performance.
fn run(comptime modifier: std.builtin.CallModifier) u32 {
    var acc: u32 = 0;
    var i: usize = 0;
    while (i < iterations) : (i += 1) {
        // The @call builtin lets us explicitly control inlining behavior at the call site
        // @call 内置 lets us explicitly control inlining behavior 在 call site
        acc = @call(modifier, mix, .{acc});
    }
    return acc;
}

pub fn main() !void {
    // Benchmark 1: Let the compiler decide whether to inline (default heuristics)
    // Benchmark 1: Let compiler decide whether 到 inline (默认 heuristics)
    var timer = try std.time.Timer.start();
    const auto_result = run(.auto);
    const auto_ns = timer.read();

    // Benchmark 2: Force inlining at every call site
    // Benchmark 2: 强制 inlining 在 每个 call site
    timer = try std.time.Timer.start();
    const inline_result = run(.always_inline);
    const inline_ns = timer.read();

    // Benchmark 3: Prevent inlining, always emit a function call
    // Benchmark 3: Prevent inlining, always emit 一个 函数 call
    timer = try std.time.Timer.start();
    const never_result = run(.never_inline);
    const never_ns = timer.read();

    // Verify all three strategies produce identical results
    // Verify 所有 三个 strategies produce identical results
    std.debug.assert(auto_result == inline_result);
    std.debug.assert(auto_result == never_result);

    // Display the optimization mode and iteration count for reproducibility
    // 显示 optimization 模式 和 iteration count 用于 reproducibility
    std.debug.print(
        "optimize-mode={s} iterations={}\n",
        .{
            @tagName(builtin.mode),
            iterations,
        },
    );
    // Report timing results for each call modifier
    // Report timing results 用于 每个 call modifier
    std.debug.print("auto call   : {d} ns\n", .{auto_ns});
    std.debug.print("always_inline: {d} ns\n", .{inline_ns});
    std.debug.print("never_inline : {d} ns\n", .{never_ns});
}
