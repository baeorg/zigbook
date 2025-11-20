const std = @import("std");

// / Prints information about a slice including its label, length, and first element.
// / Prints 信息 about 一个 切片 including its 标签, length, 和 首先 element.
// / If the slice is empty, displays -1 as the head value.
// / 如果 切片 is 空, displays -1 作为 head 值.
fn describe(label: []const u8, data: []const i32) void {
    // Get first element or -1 if slice is empty
    // 获取 首先 element 或 -1 如果 切片 is 空
    const head = if (data.len > 0) data[0] else -1;
    std.debug.print("{s}: len={} head={d}\n", .{ label, data.len, head });
}

// / Demonstrates array and slice fundamentals in Zig, including:
// / 演示 数组 和 切片 fundamentals 在 Zig, including:
// / - Array declaration and initialization
// / - 数组 declaration 和 initialization
// / - Creating slices from arrays with different mutability
// / - Creating slices 从 arrays 使用 different mutability
// / - Modifying arrays through direct indexing and slices
// / - Modifying arrays through direct indexing 和 slices
// / - Array copying behavior (value semantics)
// / - 数组 copying behavior (值 语义)
// / - Creating empty and zero-length slices
// / - Creating 空 和 零-length slices
pub fn main() !void {
    // Declare mutable array with inferred size
    // Declare mutable 数组 使用 inferred size
    var values = [_]i32{ 3, 5, 8, 13 };
    // Declare const array with explicit size using anonymous struct syntax
    // Declare const 数组 使用 explicit size 使用 anonymous struct 语法
    const owned: [4]i32 = .{ 1, 2, 3, 4 };

    // Create a mutable slice covering the entire array
    // 创建一个 mutable 切片 covering entire 数组
    var mutable_slice: []i32 = values[0..];
    // Create an immutable slice of the first two elements
    // 创建 一个 immutable 切片 的 首先 两个 elements
    const prefix: []const i32 = values[0..2];
    // Create a zero-length slice (empty but valid)
    // 创建一个 零-length 切片 (空 but valid)
    const empty = values[0..0];

    // Modify array directly by index
    // Modify 数组 directly 通过 索引
    values[1] = 99;
    // Modify array through mutable slice
    // Modify 数组 through mutable 切片
    mutable_slice[0] = -3;

    std.debug.print("array len={} allows mutation\n", .{values.len});
    describe("mutable_slice", mutable_slice);
    describe("prefix", prefix);
    // Demonstrate that slice modification affects the underlying array
    // Demonstrate 该 切片 modification affects underlying 数组
    std.debug.print("values[0] after slice write = {d}\n", .{values[0]});
    std.debug.print("empty slice len={} is zero-length\n", .{empty.len});

    // Arrays are copied by value in Zig
    // Arrays are copied 通过 值 在 Zig
    var copy = owned;
    copy[0] = -1;
    // Show that modifying the copy doesn't affect the original
    // Show 该 modifying 复制 doesn't affect 原始
    std.debug.print("copy[0]={d} owned[0]={d}\n", .{ copy[0], owned[0] });

    // Create a slice from an empty array literal using address-of operator
    // 创建一个 切片 从 一个 空 数组 字面量 使用 address-的 operator
    const zero: []const i32 = &[_]i32{};
    std.debug.print("zero slice len={} from literal\n", .{zero.len});
}
