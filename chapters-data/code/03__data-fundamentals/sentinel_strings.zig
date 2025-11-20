const std = @import("std");

// / Demonstrates sentinel-terminated strings and arrays in Zig, including:
// / 演示 sentinel-terminated 字符串 和 arrays 在 Zig, including:
// / - Zero-terminated string literals ([:0]const u8)
// / - 零-terminated string literals ([:0]const u8)
/// - Many-item sentinel pointers ([*:0]const u8)
/// - Sentinel-terminated arrays ([N:0]T)
// / - Converting between sentinel slices and regular slices
// / - Converting between sentinel slices 和 regular slices
/// - Mutation through sentinel pointers
pub fn main() !void {
    // String literals in Zig are sentinel-terminated by default with a zero byte
    // String literals 在 Zig are sentinel-terminated 通过 默认 使用 一个 零 byte
    // [:0]const u8 denotes a slice with a sentinel value of 0 at the end
    // [:0]const u8 denotes 一个 切片 使用 一个 sentinel 值 的 0 在 end
    const literal: [:0]const u8 = "data fundamentals";
    
    // Convert the sentinel slice to a many-item sentinel pointer
    // Convert sentinel 切片 到 一个 many-item sentinel pointer
    // [*:0]const u8 is compatible with C-style null-terminated strings
    // [*:0]const u8 is compatible 使用 C-style 空-terminated 字符串
    const c_ptr: [*:0]const u8 = literal;
    
    // std.mem.span converts a sentinel-terminated pointer back to a slice
    // std.mem.span converts 一个 sentinel-terminated pointer back 到 一个 切片
    // It scans until it finds the sentinel value (0) to determine the length
    // It scans until it finds sentinel 值 (0) 到 确定 length
    const bytes = std.mem.span(c_ptr);
    std.debug.print("literal len={} contents=\"{s}\"\n", .{ bytes.len, bytes });

    // Declare a sentinel-terminated array with explicit size and sentinel value
    // Declare 一个 sentinel-terminated 数组 使用 explicit size 和 sentinel 值
    // [6:0]u8 means an array of 6 elements plus a sentinel 0 byte at position 6
    // [6:0]u8 means 一个 数组 的 6 elements plus 一个 sentinel 0 byte 在 position 6
    var label: [6:0]u8 = .{ 'l', 'a', 'b', 'e', 'l', 0 };
    
    // Create a mutable sentinel slice from the array
    // 创建一个 mutable sentinel 切片 从 数组
    // The [0.. :0] syntax creates a slice from index 0 to the end, with sentinel 0
    // [0.. :0] 语法 creates 一个 切片 从 索引 0 到 end, 使用 sentinel 0
    var sentinel_view: [:0]u8 = label[0.. :0];
    
    // Modify the first element through the sentinel slice
    // Modify 首先 element through sentinel 切片
    sentinel_view[0] = 'L';

    // Create a regular (non-sentinel) slice from the first 4 elements
    // 创建一个 regular (non-sentinel) 切片 从 首先 4 elements
    // This drops the sentinel guarantees but provides a bounded slice
    // 此 drops sentinel guarantees but provides 一个 bounded 切片
    const trimmed: []const u8 = sentinel_view[0..4];
    std.debug.print("trimmed slice len={} -> {s}\n", .{ trimmed.len, trimmed });

    // Convert the sentinel slice to a many-item sentinel pointer
    // Convert sentinel 切片 到 一个 many-item sentinel pointer
    // This allows unchecked indexing while preserving sentinel information
    // 此 allows unchecked indexing 当 preserving sentinel 信息
    const tail: [*:0]u8 = sentinel_view;
    
    // Modify element at index 4 through the many-item sentinel pointer
    // Modify element 在 索引 4 through many-item sentinel pointer
    // No bounds checking occurs, but the sentinel guarantees remain valid
    // 不 bounds checking occurs, but sentinel guarantees remain valid
    tail[4] = 'X';

    // Demonstrate that mutations through the pointer affected the original array
    // Demonstrate 该 mutations through pointer affected 原始 数组
    // std.mem.span uses the sentinel to reconstruct the full slice
    // std.mem.span 使用 sentinel 到 reconstruct 满 切片
    std.debug.print("full label after mutation: {s}\n", .{std.mem.span(tail)});
}
