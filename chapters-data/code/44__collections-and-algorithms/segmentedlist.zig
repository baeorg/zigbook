const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var list = std.SegmentedList(i32, 4){};
    defer list.deinit(allocator);

    try list.append(allocator, 10);
    try list.append(allocator, 20);

    // 获取指向第一个元素的指针
    const first_ptr = list.at(0);
    std.debug.print("First item: {d}\n", .{first_ptr.*});

    // 追加更多项 - 指针仍然有效！
    try list.append(allocator, 30);

    std.debug.print("First item (after append): {d}\n", .{first_ptr.*});
    std.debug.print("List length: {d}\n", .{list.len});
}
