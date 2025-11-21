// 此示例演示使用原子操作的线程安全一次性初始化。
// 多个线程尝试初始化共享资源，但只有一个成功
// 精确执行一次昂贵的初始化。

const std = @import("std");

// 使用原子操作表示初始化状态
const State = enum(u8) { idle, busy, ready };

// 跟踪初始化生命周期的全局状态
var once_state: State = .idle;
// 将被一次性初始化的共享配置值
var config_value: i32 = 0;
// 验证初始化只发生一次的计数器
var init_calls: u32 = 0;

// 模拟只应运行一次的昂贵初始化操作。
// 使用原子操作安全地增加调用计数器并设置配置值。
fn expensiveInit() void {
    // 通过睡眠模拟昂贵的工作
    std.Thread.sleep(2 * std.time.ns_per_ms);
    // 原子性地增加初始化调用计数器
    _ = @atomicRmw(u32, &init_calls, .Add, 1, .seq_cst);
    // 使用发布语义原子性地存储初始化值
    @atomicStore(i32, &config_value, 9157, .release);
}

// 确保expensiveInit()在多个线程中只被调用一次。
// 使用带有比较和交换的状态机来协调线程访问。
fn callOnce() void {
    while (true) {
        // 使用获取语义检查当前状态以查看初始化结果
        switch (@atomicLoad(State, &once_state, .acquire)) {
            // 初始化完成，立即返回
            .ready => return,
            // 另一个线程正在初始化，让出并重试
            .busy => {
                std.Thread.yield() catch {};
                continue;
            },
            // 尚未初始化，尝试声明初始化责任
            .idle => {
                // 尝试从空闲原子性地转换到忙碌
                // 如果成功（返回null），此线程获胜并将初始化
                // 如果失败（返回实际值），另一个线程获胜，因此重试
                if (@cmpxchgStrong(State, &once_state, .idle, .busy, .acq_rel, .acquire)) |_| {
                    continue;
                }
                // 此线程成功声明了初始化
                break;
            },
        }
    }

    // 执行一次性初始化
    expensiveInit();
    // 使用发布语义将初始化标记为完成
    @atomicStore(State, &once_state, .ready, .release);
}

// 传递给每个工作线程的参数
const WorkerArgs = struct {
    results: []i32,
    index: usize,
};

// 工作线程函数，调用一次性初始化并读取结果。
fn worker(args: WorkerArgs) void {
    // 确保初始化发生（如果另一个线程正在初始化则阻塞直到完成）
    callOnce();
    // 使用获取语义读取初始化值
    const value = @atomicLoad(i32, &config_value, .acquire);
    // 将观察到的值存储在线程的结果槽中
    args.results[args.index] = value;
}

pub fn main() !void {
    // 重置全局状态用于演示
    once_state = .idle;
    config_value = 0;
    init_calls = 0;

    // 设置内存分配
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const worker_count: usize = 4;

    // 分配数组以收集每个线程的结果
    const results = try allocator.alloc(i32, worker_count);
    defer allocator.free(results);
    // 初始化所有结果槽为-1以检测是否有任何线程失败
    for (results) |*slot| slot.* = -1;

    // 分配数组以保存线程句柄
    const threads = try allocator.alloc(std.Thread, worker_count);
    defer allocator.free(threads);

    // 生成所有工作线程
    for (threads, 0..) |*thread, index| {
        thread.* = try std.Thread.spawn(.{}, worker, .{WorkerArgs{
            .results = results,
            .index = index,
        }});
    }

    // 等待所有线程完成
    for (threads) |thread| {
        thread.join();
    }

    // 所有线程完成后读取最终值
    const final_value = @atomicLoad(i32, &config_value, .acquire);
    const called = @atomicLoad(u32, &init_calls, .seq_cst);

    // 设置缓冲输出
    var stdout_buffer: [256]u8 = undefined;
    var stdout_state = std.fs.File.stdout().writer(&stdout_buffer);
    const out = &stdout_state.interface;

    // 打印每个线程观察到的值（应该都是9157）
    for (results, 0..) |value, index| {
        try out.print("thread {d} observed {d}\n", .{ index, value });
    }
    // 验证初始化只被调用一次
    try out.print("init calls: {d}\n", .{called});
    // 显示最终配置值
    try out.print("config value: {d}\n", .{final_value});
    try out.flush();
}
