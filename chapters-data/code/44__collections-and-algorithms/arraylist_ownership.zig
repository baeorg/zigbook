const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // 带显式分配器的 ArrayList
    var list: std.ArrayList(u32) = .empty;
    defer list.deinit(allocator);

    try list.append(allocator, 1);
    try list.append(allocator, 2);
    try list.append(allocator, 3);

    std.debug.print("Managed list length: {d}\n", .{list.items.len});

    // 将所有权转移到切片
    const owned_slice = try list.toOwnedSlice(allocator);
    defer allocator.free(owned_slice);

    std.debug.print("After transfer, original list length: {d}\n", .{list.items.len});
    std.debug.print("Owned slice length: {d}\n", .{owned_slice.len});
}
