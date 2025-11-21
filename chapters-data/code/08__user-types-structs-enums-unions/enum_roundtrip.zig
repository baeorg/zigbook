const std = @import("std");

// 第8章 — 枚举：整数表示、转换、穷举性检查
//
// 演示定义具有显式整数表示的枚举，
// 使用@intFromEnum和@enumFromInt在枚举和整数之间转换，
// 以及使用穷举性检查的模式匹配。
//
// 用法:
//    zig run enum_roundtrip.zig

const Mode = enum(u8) {
    Idle = 0,
    Busy = 1,
    Paused = 2,
};

fn describe(m: Mode) []const u8 {
    return switch (m) {
        .Idle => "idle",
        .Busy => "busy",
        .Paused => "paused",
    };
}

pub fn main() !void {
    const m: Mode = .Busy;
    const int_val: u8 = @intFromEnum(m);
    std.debug.print("m={s} int={d}\n", .{ describe(m), int_val });

    // 使用@enumFromInt往返；整数必须映射到声明的标签
    const m2: Mode = @enumFromInt(2);
    std.debug.print("m2={s} int={d}\n", .{ describe(m2), @intFromEnum(m2) });
}
