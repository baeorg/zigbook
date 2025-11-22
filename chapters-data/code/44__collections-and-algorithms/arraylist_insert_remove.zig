const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var list: std.ArrayList(i32) = .empty;
    defer list.deinit(allocator);

    try list.appendSlice(allocator, &.{ 1, 2, 3, 4 });

    // 在索引 1 处插入 99
    try list.insert(allocator, 1, 99);
    std.debug.print("After insert at 1: {any}\n", .{list.items});

    // 移除索引 2 处的元素（元素会移动）
    _ = list.orderedRemove(2);
    std.debug.print("After orderedRemove at 2: {any}\n", .{list.items});

    // 移除索引 1 处的元素（与最后一个元素交换，不移动）
    _ = list.swapRemove(1);
    std.debug.print("After swapRemove at 1: {any}\n", .{list.items});
}
