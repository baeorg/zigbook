const std = @import("std");

fn joinSep(allocator: std.mem.Allocator, parts: []const []const u8, sep: []const u8) ![]u8 {
    var total: usize = 0;
    for (parts) |p| total += p.len;
    if (parts.len > 0) total += sep.len * (parts.len - 1);

    var out = try allocator.alloc(u8, total);
    var i: usize = 0;

    for (parts, 0..) |p, idx| {
        @memcpy(out[i .. i + p.len], p);
        i += p.len;
        if (idx + 1 < parts.len) {
            @memcpy(out[i .. i + sep.len], sep);
            i += sep.len;
        }
    }
    return out;
}

pub fn main() !void {
    // Use GPA to build a string, then free.
    // 使用 GPA 构建字符串，然后释放。
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .init;
    defer {
        _ = gpa.deinit();
    }
    const A = gpa.allocator();

    const joined = try joinSep(A, &.{ "zig", "likes", "allocators" }, "-");
    defer A.free(joined);
    std.debug.print("gpa: {s}\n", .{joined});

    // Try with a tiny fixed buffer to demonstrate OOM.
    // 尝试使用很小的固定缓冲区来演示 OOM。
    var buf: [8]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buf);
    const B = fba.allocator();

    if (joinSep(B, &.{ "this", "is", "too", "big" }, ",")) |s| {
        // If it somehow fits, free it (unlikely with 16 bytes here).
        B.free(s);
        std.debug.print("fba unexpectedly succeeded\n", .{});
    } else |err| switch (err) {
        error.OutOfMemory => std.debug.print("fba: OOM as expected\n", .{}),
        else => return err,
    }
}
