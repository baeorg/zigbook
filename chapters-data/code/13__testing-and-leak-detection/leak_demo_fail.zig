const std = @import("std");

// This test intentionally leaks to demonstrate the testing allocator's leak detection.
// 此 test intentionally leaks 到 demonstrate testing allocator's leak detection.
// Do NOT copy this pattern into real code; see leak_demo_fix.zig for the fix.
// Do 不 复制 此 pattern into real 代码; see leak_demo_fix.zig 用于 fix.

test "leak detection catches a missing free" {
    const allocator = std.testing.allocator;

    // Intentionally leak this allocation by not freeing it.
    // Intentionally leak 此 allocation 通过 不 freeing it.
    const buf = try allocator.alloc(u8, 64);

    // Touch the memory so optimizers can't elide the allocation.
    // Touch 内存 so optimizers can't elide allocation.
    for (buf) |*b| b.* = 0xAA;

    // No free on purpose:
    // 不 释放 在 purpose:
    // allocator.free(buf);
    // allocator.释放(buf);
}
