const std = @import("std");

fn testImplGood(allocator: std.mem.Allocator, length: usize) !void {
    const a = try allocator.alloc(u8, length);
    defer allocator.free(a);
    const b = try allocator.alloc(u8, length);
    defer allocator.free(b);
}

// No "bad" implementation here; see leak_demo_fail.zig for a dedicated failing example.
// 不 "bad" implementation here; see leak_demo_fail.zig 用于 一个 dedicated failing 示例.

test "OOM injection: good implementation is leak-free" {
    const allocator = std.testing.allocator;
    try std.testing.checkAllAllocationFailures(allocator, testImplGood, .{32});
}

// Intentionally not included: a "bad" implementation under checkAllAllocationFailures
// Intentionally 不 included: 一个 "bad" implementation under checkAllAllocationFailures
// will cause the test runner to fail due to leak logging, even if you expect the error.
// will cause test runner 到 fail 由于 leak logging, even 如果 you expect 错误.
// See leak_demo_fail.zig for a dedicated failing example.
// See leak_demo_fail.zig 用于 一个 dedicated failing 示例.
