const std = @import("std");

// 第8章 — 联合体：带标签与不带标签
//
// 演示带标签的联合体（使用枚举判别符）和不带标签的联合体
// （无判别符）。带标签的联合体是安全且符合语言习惯的；不带标签的
// 联合体是高级用法，若使用不当则不安全。
//
// 用法:
//    zig run union_demo.zig

const Kind = enum { number, text };

const Value = union(Kind) {
    number: i64,
    text: []const u8,
};

// 不带标签的联合体（高级）：需要外部跟踪，若使用不当则不安全。
const Raw = union { u: u32, i: i32 };

pub fn main() !void {
    var v: Value = .{ .number = 42 };
    printValue("start: ", v);

    v = .{ .text = "hi" };
    printValue("update: ", v);

    // 不带标签的示例：以 u32 写入，以 i32 读取（位重新解释）。
    const r = Raw{ .u = 0xFFFF_FFFE }; // -2 as signed 32-bit
    const as_i: i32 = @bitCast(r.u);
    std.debug.print("raw u=0x{X:0>8} i={d}\n", .{ r.u, as_i });
}

fn printValue(prefix: []const u8, v: Value) void {
    switch (v) {
        .number => |n| std.debug.print("{s}number={d}\n", .{ prefix, n }),
        .text => |s| std.debug.print("{s}{s}\n", .{ prefix, s }),
    }
}
