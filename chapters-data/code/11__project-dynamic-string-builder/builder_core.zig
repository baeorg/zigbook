const std = @import("std");
const builder_mod = @import("string_builder.zig");
const StringBuilder = builder_mod.StringBuilder;

pub fn main() !void {
    // Initialize a general-purpose allocator with leak detection
    // Initialize 一个 general-purpose allocator 使用 leak detection
    // This allocator tracks all allocations and reports leaks on deinit
    // 此 allocator tracks 所有 allocations 和 reports leaks 在 deinit
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        if (gpa.deinit() == .leak) std.log.err("leaked allocations detected", .{});
    }
    const allocator = gpa.allocator();

    // Create a StringBuilder with 64 bytes of initial capacity
    // 创建一个 StringBuilder 使用 64 bytes 的 初始 capacity
    // Pre-allocating reduces reallocation overhead for known content size
    // Pre-allocating reduces reallocation overhead 用于 known content size
    var builder = try StringBuilder.initCapacity(allocator, 64);
    defer builder.deinit();

    // Build report header using basic string concatenation
    // 构建 report header 使用 basic string concatenation
    try builder.append("Report\n======\n");
    try builder.append("source: dynamic builder\n\n");

    // Define structured data for report generation
    // 定义 structured 数据 用于 report generation
    // Each item represents a category with its count
    // 每个 item represents 一个 category 使用 its count
    const items = [_]struct {
        name: []const u8,
        count: usize,
    }{
        .{ .name = "widgets", .count = 7 },
        .{ .name = "gadgets", .count = 13 },
        .{ .name = "doodads", .count = 2 },
    };

    // Obtain a writer interface for formatted output
    // Obtain 一个 writer 接口 用于 格式化 输出
    // This allows using std.fmt.format-style print operations
    // 此 allows 使用 std.fmt.format-style 打印 operations
    var writer = builder.writer();
    for (items, 0..) |item, index| {
        // Format each item as a numbered list entry with name and count
        // Format 每个 item 作为 一个 numbered list entry 使用 name 和 count
        try writer.print("* {d}. {s}: {d}\n", .{ index + 1, item.name, item.count });
    }

    // Capture allocation statistics before adding summary
    // 捕获 allocation statistics before adding summary
    // Snapshot preserves metrics for analysis without affecting builder state
    // Snapshot preserves metrics 用于 analysis without affecting builder state
    const snapshot = builder.snapshot();
    try writer.print("\nsummary: appended {d} entries\n", .{items.len});

    // Transfer ownership of the constructed string to caller
    // Transfer ownership 的 constructed string 到 caller
    // After this call, builder is reset and cannot be reused without re-initialization
    // After 此 call, builder is reset 和 cannot be reused without re-initialization
    const result = try builder.toOwnedSlice();
    defer allocator.free(result);

    // Display the generated report alongside allocation statistics
    // 显示 generated report alongside allocation statistics
    std.debug.print("{s}\n---\n{any}\n", .{ result, snapshot });
}
