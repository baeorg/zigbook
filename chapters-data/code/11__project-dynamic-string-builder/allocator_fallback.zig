const std = @import("std");
const builder_mod = @import("string_builder.zig");
const StringBuilder = builder_mod.StringBuilder;
const Stats = builder_mod.Stats;

// / Container for a generated report and its allocation statistics
// / Container 用于 一个 generated report 和 its allocation statistics
const Report = struct {
    text: []u8,
    stats: Stats,
};

// / Builds a text report with random sample data
// / Builds 一个 text report 使用 random sample 数据
// / Demonstrates StringBuilder usage with various allocator strategies
// / 演示 StringBuilder usage 使用 various allocator strategies
fn buildReport(allocator: std.mem.Allocator, label: []const u8, sample_count: usize) !Report {
    // Initialize StringBuilder with the provided allocator
    // Initialize StringBuilder 使用 provided allocator
    var builder = StringBuilder.init(allocator);
    defer builder.deinit();

    // Write report header
    // 写入 report header
    try builder.append("label: ");
    try builder.append(label);
    try builder.append("\n");

    // Initialize PRNG with a seed that varies based on sample_count
    // Initialize PRNG 使用 一个 seed 该 varies 基于 sample_count
    // Ensures reproducible but different sequences for different report sizes
    // 确保 reproducible but different sequences 用于 different report sizes
    var prng = std.Random.DefaultPrng.init(0x5eed1234 ^ @as(u64, sample_count));
    var random = prng.random();

    // Generate random sample data and accumulate totals
    // Generate random sample 数据 和 accumulate totals
    var total: usize = 0;
    var writer = builder.writer();
    for (0..sample_count) |i| {
        // Each sample represents a random KiB allocation between 8-64
        // 每个 sample represents 一个 random KiB allocation between 8-64
        const chunk = random.intRangeAtMost(u32, 8, 64);
        total += chunk;
        try writer.print("{d}: +{d} KiB\n", .{ i, chunk });
    }

    // Write summary line with aggregated statistics
    // 写入 summary line 使用 aggregated statistics
    try writer.print("total: {d} KiB across {d} samples\n", .{ total, sample_count });

    // Capture allocation statistics before transferring ownership
    // 捕获 allocation statistics before transferring ownership
    const stats = builder.snapshot();
    
    // Transfer ownership of the built string to the caller
    // Transfer ownership 的 built string 到 caller
    const text = try builder.toOwnedSlice();
    return .{ .text = text, .stats = stats };
}

pub fn main() !void {
    // Arena allocator will reclaim all allocations at once when deinit() is called
    // Arena allocator will reclaim 所有 allocations 在 once 当 deinit() is called
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    // Small report: 256-byte stack buffer should be sufficient
    // Small report: 256-byte 栈 缓冲区 should be sufficient
    // stackFallback tries stack first, falls back to arena if needed
    // stackFallback tries 栈 首先, falls back 到 arena 如果 needed
    var fallback_small = std.heap.stackFallback(256, arena.allocator());
    const small_allocator = fallback_small.get();
    const small = try buildReport(small_allocator, "stack-only", 6);
    defer small_allocator.free(small.text);

    // Large report: 256-byte stack buffer will overflow, forcing arena allocation
    // Large report: 256-byte 栈 缓冲区 will overflow, forcing arena allocation
    // Demonstrates fallback behavior when stack space is insufficient
    // 演示 fallback behavior 当 栈 space is insufficient
    var fallback_large = std.heap.stackFallback(256, arena.allocator());
    const large_allocator = fallback_large.get();
    const large = try buildReport(large_allocator, "needs-arena", 48);
    defer large_allocator.free(large.text);

    // Display both reports with their allocation statistics
    // 显示 both reports 使用 their allocation statistics
    // Stats will reveal which allocator strategy was used (stack vs heap)
    // Stats will reveal which allocator strategy was used (栈 vs 堆)
    std.debug.print("small buffer ->\n{s}stats: {any}\n\n", .{ small.text, small.stats });
    std.debug.print("large buffer ->\n{s}stats: {any}\n", .{ large.text, large.stats });
}
