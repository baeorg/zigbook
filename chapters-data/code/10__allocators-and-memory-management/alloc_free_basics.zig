const std = @import("std");

pub fn main() !void {
    const allocator = std.heap.page_allocator; // OS-backed; fast & simple

    // Allocate a small buffer and fill it.
    // 分配 一个 small 缓冲区 和 fill it.
    const buf = try allocator.alloc(u8, 5);
    defer allocator.free(buf);

    for (buf, 0..) |*b, i| b.* = 'a' + @as(u8, @intCast(i));
    std.debug.print("buf: {s}\n", .{buf});

    // Create/destroy a single item.
    // 创建/destroy 一个 single item.
    const Point = struct { x: i32, y: i32 };
    const p = try allocator.create(Point);
    defer allocator.destroy(p);
    p.* = .{ .x = 7, .y = -3 };
    std.debug.print("point: (x={}, y={})\n", .{ p.x, p.y });

    // Allocate a null-terminated string (sentinel). Great for C APIs.
    // 分配 一个 空-terminated string (sentinel). Great 用于 C APIs.
    var hello = try allocator.allocSentinel(u8, 5, 0);
    defer allocator.free(hello);
    @memcpy(hello[0..5], "hello");
    std.debug.print("zstr: {s}\n", .{hello});
}
