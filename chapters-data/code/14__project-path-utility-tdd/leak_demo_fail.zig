const std = @import("std");
const testing = std.testing;
const pathutil = @import("path_util.zig").pathutil;

test "deliberate leak caught by testing allocator" {
    const joined = try pathutil.joinAlloc(testing.allocator, &.{ "/", "tmp", "demo" });
    // Intentionally forget to free: allocator leak should be detected by the runner
    // Intentionally forget 到 释放: allocator leak should be detected 通过 runner
    // defer testing.allocator.free(joined);
    // defer testing.allocator.释放(joined);
    try testing.expect(std.mem.endsWith(u8, joined, "demo"));
}
