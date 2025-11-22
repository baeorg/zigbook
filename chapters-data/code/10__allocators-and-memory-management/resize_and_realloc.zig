const std = @import("std");

pub fn main() !void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .init;
    defer { _ = gpa.deinit(); }
    const alloc = gpa.allocator();

    var buf = try alloc.alloc(u8, 4);
    defer alloc.free(buf);
    for (buf, 0..) |*b, i| b.* = 'A' + @as(u8, @intCast(i));
    std.debug.print("len={} contents={s}\n", .{ buf.len, buf });

    // 使用 realloc 增长（可能会移动内存）。
    buf = try alloc.realloc(buf, 8);
    for (buf[4..], 0..) |*b, i| b.* = 'a' + @as(u8, @intCast(i));
    std.debug.print("grown len={} contents={s}\n", .{ buf.len, buf });

    // 使用 resize 原地缩小；记得切片。
    if (alloc.resize(buf, 3)) {
        buf = buf[0..3];
        std.debug.print("shrunk len={} contents={s}\n", .{ buf.len, buf });
    } else {
        // 当分配器不支持原地缩小时的回退方案。
        buf = try alloc.realloc(buf, 3);
        std.debug.print("shrunk (realloc) len={} contents={s}\n", .{ buf.len, buf });
    }
}
