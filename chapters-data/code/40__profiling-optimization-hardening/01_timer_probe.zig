// This program demonstrates performance measurement and comparison of different
// 此 program 演示 performance measurement 和 comparison 的 different
// sorting algorithms using Zig's built-in Timer for benchmarking.
// sorting algorithms 使用 Zig's built-在 Timer 用于 benchmarking.
const std = @import("std");

// Number of elements to sort in each benchmark run
// 数字 的 elements 到 sort 在 每个 benchmark run
const sample_count = 1024;

// / Generates a deterministic array of random u32 values for benchmarking.
// / Generates 一个 deterministic 数组 的 random u32 值 用于 benchmarking.
// / Uses a fixed seed to ensure reproducible results across multiple runs.
// / 使用 一个 fixed seed 到 确保 reproducible results across multiple runs.
// / @return: Array of 1024 pseudo-random u32 values
// / @返回: 数组 的 1024 pseudo-random u32 值
fn generateData() [sample_count]u32 {
    var data: [sample_count]u32 = undefined;
    // Initialize PRNG with fixed seed for deterministic output
    // Initialize PRNG 使用 fixed seed 用于 deterministic 输出
    var prng = std.Random.DefaultPrng.init(0xfeed_beef_dead_cafe);
    var random = prng.random();
    // Fill each array slot with a random 32-bit unsigned integer
    // Fill 每个 数组 slot 使用 一个 random 32-bit unsigned integer
    for (&data) |*slot| {
        slot.* = random.int(u32);
    }
    return data;
}

// / Measures the execution time of a sorting function on a copy of the input data.
// / Measures execution time 的 一个 sorting 函数 在 一个 复制 的 输入 数据.
// / Creates a scratch buffer to avoid modifying the original data, allowing
// / Creates 一个 scratch 缓冲区 到 avoid modifying 原始 数据, allowing
// / multiple measurements on the same dataset.
// / multiple measurements 在 same dataset.
// / @param sortFn: Compile-time sorting function to benchmark
// / @param sortFn: 编译-time sorting 函数 到 benchmark
// / @param source: Source data to sort (remains unchanged)
// / @param 源文件: 源文件 数据 到 sort (remains unchanged)
// / @return: Elapsed time in nanoseconds
// / @返回: Elapsed time 在 nanoseconds
fn measureSort(
    comptime sortFn: anytype,
    source: []const u32,
) !u64 {
    // Create scratch buffer to preserve original data
    // 创建 scratch 缓冲区 到 preserve 原始 数据
    var scratch: [sample_count]u32 = undefined;
    std.mem.copyForwards(u32, scratch[0..], source);

    // Start high-resolution timer immediately before sort operation
    var timer = try std.time.Timer.start();
    // Execute the sort with ascending comparison function
    // Execute sort 使用 ascending comparison 函数
    sortFn(u32, scratch[0..], {}, std.sort.asc(u32));
    // Capture elapsed nanoseconds
    // 捕获 elapsed nanoseconds
    return timer.read();
}

pub fn main() !void {
    // Generate shared dataset for all sorting algorithms
    // Generate shared dataset 用于 所有 sorting algorithms
    var dataset = generateData();

    // Benchmark each sorting algorithm on identical data
    // Benchmark 每个 sorting algorithm 在 identical 数据
    const block_ns = try measureSort(std.sort.block, dataset[0..]);
    const heap_ns = try measureSort(std.sort.heap, dataset[0..]);
    const insertion_ns = try measureSort(std.sort.insertion, dataset[0..]);

    // Display raw timing results along with build mode
    // 显示 raw timing results along 使用 构建模式
    std.debug.print("optimize-mode={s}\n", .{@tagName(@import("builtin").mode)});
    std.debug.print("block sort     : {d} ns\n", .{block_ns});
    std.debug.print("heap sort      : {d} ns\n", .{heap_ns});
    std.debug.print("insertion sort : {d} ns\n", .{insertion_ns});

    // Calculate relative performance metrics using block sort as baseline
    // Calculate relative performance metrics 使用 block sort 作为 baseline
    const baseline = @as(f64, @floatFromInt(block_ns));
    const heap_speedup = baseline / @as(f64, @floatFromInt(heap_ns));
    const insertion_slowdown = @as(f64, @floatFromInt(insertion_ns)) / baseline;

    // Display comparative analysis showing speedup/slowdown factors
    // 显示 comparative analysis showing speedup/slowdown factors
    std.debug.print("heap speedup over block: {d:.2}x\n", .{heap_speedup});
    std.debug.print("insertion slowdown vs block: {d:.2}x\n", .{insertion_slowdown});
}
