const std = @import("std");

/// 演示Zig中的哨兵终止字符串和数组，包括：
/// - 零终止字符串字面量（[:0]const u8）
/// - 多项哨兵指针（[*:0]const u8）
/// - 哨兵终止数组（[N:0]T）
/// - 哨兵切片与常规切片之间的转换
/// - 通过哨兵指针进行修改
pub fn main() !void {
    // Zig中的字符串字面量默认以零字节哨兵终止
    // [:0]const u8表示在末尾有哨兵值0的切片
    const literal: [:0]const u8 = "data fundamentals";

    // 将哨兵切片转换为多项哨兵指针
    // [*:0]const u8与C风格空终止字符串兼容
    const c_ptr: [*:0]const u8 = literal;

    // std.mem.span将哨兵终止指针转换回切片
    // 它扫描直到找到哨兵值（0）以确定长度
    const bytes = std.mem.span(c_ptr);
    std.debug.print("literal len={} contents=\"{s}\"\n", .{ bytes.len, bytes });

    // 声明具有显式大小和哨兵值的哨兵终止数组
    // [6:0]u8表示6个元素的数组加上位置6的哨兵0字节
    var label: [6:0]u8 = .{ 'l', 'a', 'b', 'e', 'l', 0 };

    // 从数组创建可变哨兵切片
    // [0..:0]语法从索引0到末尾创建切片，带有哨兵0
    var sentinel_view: [:0]u8 = label[0.. :0];

    // 通过哨兵切片修改第一个元素
    sentinel_view[0] = 'L';

    // 从前4个元素创建常规（非哨兵）切片
    // 这会放弃哨兵保证但提供有界切片
    const trimmed: []const u8 = sentinel_view[0..4];
    std.debug.print("trimmed slice len={} -> {s}\n", .{ trimmed.len, trimmed });

    // 将哨兵切片转换为多项哨兵指针
    // 这允许unchecked索引，同时保留哨兵信息
    const tail: [*:0]u8 = sentinel_view;

    // 通过多项哨兵指针修改索引4处的元素
    // 不会发生边界检查，但哨兵保证仍然有效
    tail[4] = 'X';

    // 演示通过指针的修改影响了原始数组
    // std.mem.span使用哨兵重建完整切片
    std.debug.print("full label after mutation: {s}\n", .{std.mem.span(tail)});
}
