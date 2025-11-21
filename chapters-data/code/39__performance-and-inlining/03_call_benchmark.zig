const std = @import("std");
const builtin = @import("builtin");

// 运行每个基准变体的迭代次数
const iterations: usize = 5_000_000;

// 演示内联性能影响的简单混合函数。
// 使用位旋转和算术运算创建非平凡的工作负载，
// 优化器可能根据调用修饰符以不同方式处理。
fn mix(value: u32) u32 {
    // 与类素数常量异或后左旋7位
    const rotated = std.math.rotl(u32, value ^ 0x9e3779b9, 7);
    // 使用环绕算术应用额外混合以防止编译时求值
    return rotated *% 0x85eb_ca6b +% 0xc2b2_ae35;
}

// 使用指定的调用修饰符在紧循环中运行混合函数。
// 这允许直接比较不同内联策略如何影响性能。
fn run(comptime modifier: std.builtin.CallModifier) u32 {
    var acc: u32 = 0;
    var i: usize = 0;
    while (i < iterations) : (i += 1) {
        // @call内置函数让我们在调用点显式控制内联行为
        acc = @call(modifier, mix, .{acc});
    }
    return acc;
}

pub fn main() !void {
    // 基准测试1：让编译器决定是否内联（默认启发式）
    var timer = try std.time.Timer.start();
    const auto_result = run(.auto);
    const auto_ns = timer.read();

    // 基准测试2：在每个调用点强制内联
    timer = try std.time.Timer.start();
    const inline_result = run(.always_inline);
    const inline_ns = timer.read();

    // 基准测试3：防止内联，始终发出函数调用
    timer = try std.time.Timer.start();
    const never_result = run(.never_inline);
    const never_ns = timer.read();

    // 验证所有三种策略产生相同的结果
    std.debug.assert(auto_result == inline_result);
    std.debug.assert(auto_result == never_result);

    // 显示优化模式和迭代次数以确保可重现性
    std.debug.print(
        "optimize-mode={s} iterations={}\n",
        .{
            @tagName(builtin.mode),
            iterations,
        },
    );
    // 报告每个调用修饰符的计时结果
    std.debug.print("auto call   : {d} ns\n", .{auto_ns});
    std.debug.print("always_inline: {d} ns\n", .{inline_ns});
    std.debug.print("never_inline : {d} ns\n", .{never_ns});
}
