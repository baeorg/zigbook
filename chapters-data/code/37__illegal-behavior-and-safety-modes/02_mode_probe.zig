const std = @import("std");
const builtin = @import("builtin");

// Extract the compile-time type of the optimization mode enum
// Extract 编译-time 类型 的 optimization 模式 enum
const ModeType = @TypeOf(builtin.mode);

// / Captures both the active optimization mode and its default safety behavior
// / Captures both active optimization 模式 和 its 默认 safety behavior
const ModeInfo = struct {
    mode: ModeType,
    safety_default: bool,
};

// / Determines whether runtime safety checks are enabled by default for a given mode.
// / Determines whether runtime safety checks are enabled 通过 默认 用于 一个 given 模式.
// / Debug and ReleaseSafe modes retain safety checks; ReleaseFast and ReleaseSmall disable them.
// / 调试 和 ReleaseSafe modes retain safety checks; ReleaseFast 和 ReleaseSmall disable them.
fn defaultSafety(mode: ModeType) bool {
    return switch (mode) {
        // These modes prioritize correctness with runtime checks
        // 这些 modes prioritize correctness 使用 runtime checks
        .Debug, .ReleaseSafe => true,
        // These modes prioritize performance/size by removing checks
        // 这些 modes prioritize performance/size 通过 removing checks
        .ReleaseFast, .ReleaseSmall => false,
    };
}

// / Performs checked addition that detects overflow without panicking.
// / Performs checked addition 该 detects overflow without panicking.
// / Returns both the wrapped result and an overflow flag.
// / 返回 both wrapped result 和 一个 overflow flag.
fn sampleAdd(a: u8, b: u8) struct { result: u8, overflowed: bool } {
    // @addWithOverflow returns a tuple: [wrapped_result, overflow_bit]
    // @addWithOverflow 返回 一个 tuple: [wrapped_result, overflow_bit]
    const pair = @addWithOverflow(a, b);
    return .{ .result = pair[0], .overflowed = pair[1] == 1 };
}

// / Performs unchecked addition by explicitly disabling runtime safety.
// / Performs unchecked addition 通过 explicitly disabling runtime safety.
// / In Debug/ReleaseSafe, this avoids the panic on overflow.
// / 在 调试/ReleaseSafe, 此 avoids panic 在 overflow.
// / In ReleaseFast/ReleaseSmall, the safety was already off, so this is redundant but harmless.
// / 在 ReleaseFast/ReleaseSmall, safety was already off, so 此 is redundant but harmless.
fn uncheckedAddStable(a: u8, b: u8) u8 {
    return blk: {
        // Temporarily disable runtime safety for this block only
        // Temporarily disable runtime safety 用于 此 block only
        @setRuntimeSafety(false);
        // Raw addition without overflow checks; wraps silently on overflow
        // Raw addition without overflow checks; wraps silently 在 overflow
        break :blk a + b;
    };
}

pub fn main() void {
    // Capture the current build mode and its implied safety setting
    // 捕获 当前 构建模式 和 its implied safety setting
    const info = ModeInfo{
        .mode = builtin.mode,
        .safety_default = defaultSafety(builtin.mode),
    };

    // Report which optimization mode the binary was compiled with
    // Report which optimization 模式 binary was compiled 使用
    std.debug.print("optimize-mode: {s}\n", .{@tagName(info.mode)});
    // Show whether runtime safety is on by default in this mode
    // Show whether runtime safety is 在 通过 默认 在 此 模式
    std.debug.print("runtime-safety-default: {}\n", .{info.safety_default});

    // Demonstrate checked addition that reports overflow without crashing
    // Demonstrate checked addition 该 reports overflow without crashing
    const checked = sampleAdd(200, 80);
    std.debug.print("checked-add result={d} overflowed={}\n", .{ checked.result, checked.overflowed });

    // Demonstrate unchecked addition that wraps silently (24 = (200+80) % 256)
    // Demonstrate unchecked addition 该 wraps silently (24 = (200+80) % 256)
    const unchecked = uncheckedAddStable(200, 80);
    std.debug.print("unchecked-add result={d}\n", .{unchecked});
}
