// 此示例演示在Zig中使用线程和原子操作进行并行计算。
// 它通过在多个线程之间分配工作来计算数组中偶数的和。
const std = @import("std");

// 传递给每个工作线程用于并行处理的参数
const WorkerArgs = struct {
    slice: []const u64,              // 该工作线程应处理的数字子集
    sum: *std.atomic.Value(u64),     // 用于线程安全累加的共享原子计数器
};

// 工作函数，从其分配的切片中累加偶数
// 每个线程在其自己的数据分区上独立运行此函数
fn accumulate(args: WorkerArgs) void {
    // 使用局部变量以最小化原子操作（性能优化）
    var local_total: u64 = 0;
    for (args.slice) |value| {
        if (value % 2 == 0) {
            local_total += value;
        }
    }

    // 使用顺序一致性排序原子性地将局部结果添加到共享总和
    // 这确保所有线程都能看到共享状态的一致视图
    _ = args.sum.fetchAdd(local_total, .seq_cst);
}

pub fn main() !void {
    // 设置带自动泄漏检测的内存分配器
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // 分配64个数字的数组用于演示
    var numbers = try allocator.alloc(u64, 64);
    defer allocator.free(numbers);

    // 用模式：index * 7 + 3 的值初始化数组
    for (numbers, 0..) |*slot, index| {
        slot.* = @as(u64, @intCast(index * 7 + 3));
    }

    // 初始化所有线程将安全更新的共享原子计数器
    var shared_sum = std.atomic.Value(u64).init(0);

    // 根据可用CPU核心数确定最优工作线程数
    const cpu_count = std.Thread.getCpuCount() catch 1;
    const desired = if (cpu_count == 0) 1 else cpu_count;
    // 不要创建比要处理的数字更多的线程
    const worker_limit = @min(numbers.len, desired);

    // 分配并行工作线程的线程句柄
    var threads = try allocator.alloc(std.Thread, worker_limit);
    defer allocator.free(threads);

    // 计算块大小，向上舍入以确保覆盖所有元素
    const chunk = (numbers.len + worker_limit - 1) / worker_limit;

    // 生成工作线程，将数组分配为大致相等的块
    var start: usize = 0;
    var spawned: usize = 0;
    while (start < numbers.len and spawned < worker_limit) : (spawned += 1) {
        const remaining = numbers.len - start;
        // 让最后一个线程处理所有剩余元素以处理不均匀的除法
        const take = if (worker_limit - spawned == 1) remaining else @min(chunk, remaining);
        const end = start + take;

        // 使用其分配的切片和共享累加器生成线程
        threads[spawned] = try std.Thread.spawn(.{}, accumulate, .{WorkerArgs{
            .slice = numbers[start..end],
            .sum = &shared_sum,
        }});

        start = end;
    }

    // 跟踪实际生成了多少线程（可能少于worker_limit）
    const used_threads = spawned;

    // 等待所有工作线程完成其工作
    for (threads[0..used_threads]) |thread| {
        thread.join();
    }

    // 从原子共享总和读取最终累加结果
    const even_sum = shared_sum.load(.seq_cst);

    // 执行顺序计算以验证并行计算的正确性
    var sequential: u64 = 0;
    for (numbers) |value| {
        if (value % 2 == 0) {
            sequential += value;
        }
    }

    // 设置缓冲stdout写入器以实现高效输出
    var stdout_buffer: [256]u8 = undefined;
    var stdout_state = std.fs.File.stdout().writer(&stdout_buffer);
    const out = &stdout_state.interface;

    // 显示结果：线程数和并行与顺序总和
    try out.print("spawned {d} worker(s)\n", .{used_threads});
    try out.print("even sum (threads): {d}\n", .{even_sum});
    try out.print("even sum (sequential check): {d}\n", .{sequential});
    try out.flush();
}
