const std = @import("std");
const builtin = @import("builtin");

// Extract the compile-time type of the optimization mode enum
// 提取优化模式枚举的编译时类型
const ModeType = @TypeOf(builtin.mode);

// / Captures both the active optimization mode and its default safety behavior
// / 捕获活动优化模式及其默认安全行为
const ModeInfo = struct {
    mode: ModeType,
    safety_default: bool,
};

// / Determines whether runtime safety checks are enabled by default for a given mode.
// / 确定给定模式是否默认启用运行时安全检查。
// / Debug and ReleaseSafe modes retain safety checks; ReleaseFast and ReleaseSmall disable them.
// / Debug 和 ReleaseSafe 模式保留安全检查；ReleaseFast 和 ReleaseSmall 禁用它们。
fn defaultSafety(mode: ModeType) bool {
    return switch (mode) {
        // These modes prioritize correctness with runtime checks
        // 这些模式优先考虑正确性，带有运行时检查
        .Debug, .ReleaseSafe => true,
        // These modes prioritize performance/size by removing checks
        // 这些模式优先考虑性能/大小，通过移除检查
        .ReleaseFast, .ReleaseSmall => false,
    };
}

// / Performs checked addition that detects overflow without panicking.
// / 执行检查加法，无需 panic 即可检测溢出。
// / Returns both the wrapped result and an overflow flag.
// / 返回包装结果和溢出标志。
fn sampleAdd(a: u8, b: u8) struct { result: u8, overflowed: bool } {
    // @addWithOverflow returns a tuple: [wrapped_result, overflow_bit]
    // @addWithOverflow 返回一个元组：[包装结果, 溢出位]
    const pair = @addWithOverflow(a, b);
    return .{ .result = pair[0], .overflowed = pair[1] == 1 };
}

// / Performs unchecked addition by explicitly disabling runtime safety.
// / In Debug/ReleaseSafe, this avoids the panic on overflow.
// / In ReleaseFast/ReleaseSmall, the safety was already off, so this is redundant but harmless.
fn uncheckedAddStable(a: u8, b: u8) u8 {
    return blk: {
        // Temporarily disable runtime safety for this block only
        @setRuntimeSafety(false);
        // Raw addition without overflow checks; wraps silently on overflow
        break :blk a + b;
    };
}

pub fn main() void {
    // Capture the current build mode and its implied safety setting
    const info = ModeInfo{
        .mode = builtin.mode,
        .safety_default = defaultSafety(builtin.mode),
    };

    // Report which optimization mode the binary was compiled with
    std.debug.print("optimize-mode: {s}\n", .{@tagName(info.mode)});
    // Show whether runtime safety is on by default in this mode
    std.debug.print("runtime-safety-default: {}\n", .{info.safety_default});

    // Demonstrate checked addition that reports overflow without crashing
    const checked = sampleAdd(200, 80);
    std.debug.print("checked-add result={d} overflowed={}\n", .{ checked.result, checked.overflowed });

    // Demonstrate unchecked addition that wraps silently (24 = (200+80) % 256)
    const unchecked = uncheckedAddStable(200, 80);
    std.debug.print("unchecked-add result={d}\n", .{unchecked});
}
