// ! 使用内联汇编输出读取 x86 时间戳计数器。
const std = @import("std");
const builtin = @import("builtin");

pub fn readTimeStampCounter() u64 {
    if (builtin.cpu.arch != .x86_64) @compileError("rdtsc example requires x86_64");

    var lo: u32 = undefined;
    var hi: u32 = undefined;
    asm volatile ("rdtsc"
        : [low] "={eax}" (lo),
          [high] "={edx}" (hi),
    );
    return (@as(u64, hi) << 32) | @as(u64, lo);
}

test "readTimeStampCounter returns non-zero" {
    const a = readTimeStampCounter();
    const b = readTimeStampCounter();
    // 计数器单调递增；在调用落在同一周期的情况下允许相等。
    try std.testing.expect(b >= a);
}
