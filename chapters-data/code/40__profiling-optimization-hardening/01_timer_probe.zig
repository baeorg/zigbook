// 此程序演示使用Zig内置计时器进行性能测量和比较不同排序算法。
const std = @import("std");

// 每个基准运行中要排序的元素数量
const sample_count = 1024;

/// 为基准测试生成确定性随机u32值数组。
/// 使用固定种子确保跨多次运行的结果可重现。
/// @return: 1024个伪随机u32值的数组
fn generateData() [sample_count]u32 {
    var data: [sample_count]u32 = undefined;
    // 用固定种子初始化PRNG以生成确定性输出
    var prng = std.Random.DefaultPrng.init(0xfeed_beef_dead_cafe);
    var random = prng.random();
    // 用随机32位无符号整数填充每个数组槽
    for (&data) |*slot| {
        slot.* = random.int(u32);
    }
    return data;
}

/// 测量排序函数在输入数据副本上的执行时间。
/// 创建临时缓冲区以避免修改原始数据，允许
/// 对同一数据集进行多次测量。
/// @param sortFn: 要基准测试的编译时排序函数
/// @param source: 要排序的源数据（保持不变）
/// @return: 以纳秒为单位的经过时间
fn measureSort(
    comptime sortFn: anytype,
    source: []const u32,
) !u64 {
    // 创建临时缓冲区以保留原始数据
    var scratch: [sample_count]u32 = undefined;
    std.mem.copyForwards(u32, scratch[0..], source);

    // 在排序操作前立即启动高分辨率计时器
    var timer = try std.time.Timer.start();
    // 使用升序比较函数执行排序
    sortFn(u32, scratch[0..], {}, std.sort.asc(u32));
    // 捕获经过的纳秒数
    return timer.read();
}

pub fn main() !void {
    // 为所有排序算法生成共享数据集
    var dataset = generateData();

    // 在相同数据上对每个排序算法进行基准测试
    const block_ns = try measureSort(std.sort.block, dataset[0..]);
    const heap_ns = try measureSort(std.sort.heap, dataset[0..]);
    const insertion_ns = try measureSort(std.sort.insertion, dataset[0..]);

    // 显示原始计时结果以及构建模式
    std.debug.print("optimize-mode={s}\n", .{@tagName(@import("builtin").mode)});
    std.debug.print("block sort     : {d} ns\n", .{block_ns});
    std.debug.print("heap sort      : {d} ns\n", .{heap_ns});
    std.debug.print("insertion sort : {d} ns\n", .{insertion_ns});

    // 使用块排序作为基线计算相对性能指标
    const baseline = @as(f64, @floatFromInt(block_ns));
    const heap_speedup = baseline / @as(f64, @floatFromInt(heap_ns));
    const insertion_slowdown = @as(f64, @floatFromInt(insertion_ns)) / baseline;

    // 显示显示加速/减速因子的比较分析
    std.debug.print("heap speedup over block: {d:.2}x\n", .{heap_speedup});
    std.debug.print("insertion slowdown vs block: {d:.2}x\n", .{insertion_slowdown});
}
