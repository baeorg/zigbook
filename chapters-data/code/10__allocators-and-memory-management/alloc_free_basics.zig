const std = @import("std");

pub fn main() !void {
    const allocator = std.heap.page_allocator; // 操作系统支持；快速且简单

    // 分配一个小缓冲区并填充它
    const buf = try allocator.alloc(u8, 5);
    defer allocator.free(buf);

    for (buf, 0..) |*b, i| b.* = 'a' + @as(u8, @intCast(i));
    std.debug.print("buf: {s}\n", .{buf});

    // 创建/销毁单个项目
    const Point = struct { x: i32, y: i32 };
    const p = try allocator.create(Point);
    defer allocator.destroy(p);
    p.* = .{ .x = 7, .y = -3 };
    std.debug.print("point: (x={}, y={})\n", .{ p.x, p.y });

    // 分配空终止字符串（哨兵）。非常适合C API
    var hello = try allocator.allocSentinel(u8, 5, 0);
    defer allocator.free(hello);
    @memcpy(hello[0..5], "hello");
    std.debug.print("zstr: {s}\n", .{hello});
}
