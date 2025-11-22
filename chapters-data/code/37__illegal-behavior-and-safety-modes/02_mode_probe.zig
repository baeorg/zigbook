const std = @import("std");
const builtin = @import("builtin");

// Extract the compile-time type of the optimization mode enum
// 提取优化模式枚举的编译时类型
const ModeType = @TypeOf(builtin.mode);

// / 捕获活动优化模式及其默认安全行为
const ModeInfo = struct {
    mode: ModeType,
    safety_default: bool,
};

// / 确定给定模式是否默认启用运行时安全检查。
// / Debug 和 ReleaseSafe 模式保留安全检查；ReleaseFast 和 ReleaseSmall 禁用它们。
fn defaultSafety(mode: ModeType) bool {
    return switch (mode) {
        // 这些模式优先考虑正确性，带有运行时检查
        .Debug, .ReleaseSafe => true,
        // 这些模式优先考虑性能/大小，通过移除检查
        .ReleaseFast, .ReleaseSmall => false,
    };
}

// / 执行检查加法，无需 panic 即可检测溢出。
// / 返回包装结果和溢出标志。
fn sampleAdd(a: u8, b: u8) struct { result: u8, overflowed: bool } {
    // @addWithOverflow 返回一个元组：[包装结果, 溢出位]
    const pair = @addWithOverflow(a, b);
    return .{ .result = pair[0], .overflowed = pair[1] == 1 };
}

// / 通过显式禁用运行时安全来执行未检查的加法。
// / 在 Debug/ReleaseSafe 模式下，这避免了溢出时的 panic。
// / 在 ReleaseFast/ReleaseSmall 模式下，安全已关闭，因此这是多余但无害的。
fn uncheckedAddStable(a: u8, b: u8) u8 {
    return blk: {
        // 仅为此块临时禁用运行时安全
        @setRuntimeSafety(false);
        // 不带溢出检查的原始加法；溢出时静默环绕
        break :blk a + b;
    };
}

pub fn main() void {
    // 捕获当前构建模式及其隐含的安全设置
    const info = ModeInfo{
        .mode = builtin.mode,
        .safety_default = defaultSafety(builtin.mode),
    };

    // 报告编译此二进制文件时使用的优化模式
    std.debug.print("optimize-mode: {s}\n", .{@tagName(info.mode)});
    // 显示此模式下是否默认开启运行时安全
    std.debug.print("runtime-safety-default: {}\n", .{info.safety_default});

    // 演示检查过的加法，报告溢出而不崩溃
    const checked = sampleAdd(200, 80);
    std.debug.print("checked-add result={d} overflowed={}\n", .{ checked.result, checked.overflowed });

    // 演示未检查的加法，静默环绕（24 = (200+80) % 256）
    const unchecked = uncheckedAddStable(200, 80);
    std.debug.print("unchecked-add result={d}\n", .{unchecked});
}
