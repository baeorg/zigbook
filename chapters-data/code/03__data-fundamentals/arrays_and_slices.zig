const std = @import("std");

/// 打印切片的详细信息，包括标签、长度和首元素
/// 如果切片为空，显示 -1 作为首元素的值
fn describe(label: []const u8, data: []const i32) void {
    // 获取首元素，如果切片为空则返回 -1
    const head = if (data.len > 0) data[0] else -1;
    std.debug.print("{s}: len={} head={d}\n", .{ label, data.len, head });
}

/// 演示 Zig 中数组和切片的基础知识，包括：
/// - 数组声明和初始化
/// - 从不同可变性的数组创建切片
/// - 通过直接索引和切片修改数组
/// - 数组复制行为（值语义）
/// - 创建空切片和零长度切片
pub fn main() !void {
    // 声明可推断大小的可变数组
    var values = [_]i32{ 3, 5, 8, 13 };
    // 使用匿名结构语法声明显式大小的常量数组
    const owned: [4]i32 = .{ 1, 2, 3, 4 };

    // 创建覆盖整个数组的可变切片
    var mutable_slice: []i32 = values[0..];
    // 创建前两个元素的不可变切片
    const prefix: []const i32 = values[0..2];
    // 创建零长度切片（空但有效）
    const empty = values[0..0];

    // 通过索引直接修改数组
    values[1] = 99;
    // 通过可变切片修改数组
    mutable_slice[0] = -3;

    std.debug.print("array len={} allows mutation\n", .{values.len});
    describe("mutable_slice", mutable_slice);
    describe("prefix", prefix);
    // 演示切片修改会影响底层数组
    std.debug.print("values[0] after slice write = {d}\n", .{values[0]});
    std.debug.print("empty slice len={} is zero-length\n", .{empty.len});

    // 在 Zig 中数组按值复制
    var copy = owned;
    copy[0] = -1;
    // 显示修改副本不会影响原始数组
    std.debug.print("copy[0]={d} owned[0]={d}\n", .{ copy[0], owned[0] });

    // Create a slice from an empty array literal using address-of operator
    // 从空数组字面量创建切片使用取地址运算符
    const zero: []const i32 = &[_]i32{};
    std.debug.print("zero slice len={} from literal\n", .{zero.len});
}
