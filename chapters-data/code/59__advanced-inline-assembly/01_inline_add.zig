// ! Minimal inline assembly example that adds two integers.
// ! 最小化 inline assembly 示例 该 adds 两个 整数.
const std = @import("std");

pub fn addAsm(a: u32, b: u32) u32 {
    var result: u32 = undefined;
    asm volatile ("addl %[lhs], %[rhs]\n\t"
        : [out] "=r" (result),
        : [lhs] "r" (a),
          [rhs] "0" (b),
    );
    return result;
}

test "addAsm produces sum" {
    try std.testing.expectEqual(@as(u32, 11), addAsm(5, 6));
}
