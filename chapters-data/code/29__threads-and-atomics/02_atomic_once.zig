
// This example demonstrates thread-safe one-time initialization using atomic operations.
// 此 示例 演示 thread-安全 一个-time initialization 使用 原子 operations.
// Multiple threads attempt to initialize a shared resource, but only one succeeds in
// Multiple threads 尝试 initialize 一个 shared resource, but only 一个 succeeds 在
// performing the expensive initialization exactly once.
// performing expensive initialization exactly once.

const std = @import("std");

// Represents the initialization state using atomic operations
// Represents initialization state 使用 原子 operations
const State = enum(u8) { idle, busy, ready };

// Global state tracking the initialization lifecycle
// Global state tracking initialization lifecycle
var once_state: State = .idle;
// The shared configuration value that will be initialized once
// shared configuration 值 该 will be initialized once
var config_value: i32 = 0;
// Counter to verify that initialization only happens once
// Counter 到 verify 该 initialization only happens once
var init_calls: u32 = 0;

// Simulates an expensive initialization operation that should only run once.
// Simulates 一个 expensive initialization operation 该 should only run once.
// Uses atomic operations to safely increment the call counter and set the config value.
// 使用 原子 operations 到 safely increment call counter 和 set config 值.
fn expensiveInit() void {
    // Simulate expensive work with a sleep
    // Simulate expensive work 使用 一个 sleep
    std.Thread.sleep(2 * std.time.ns_per_ms);
    // Atomically increment the initialization call counter
    // Atomically increment initialization call counter
    _ = @atomicRmw(u32, &init_calls, .Add, 1, .seq_cst);
    // Atomically store the initialized value with release semantics
    // Atomically store initialized 值 使用 发布 语义
    @atomicStore(i32, &config_value, 9157, .release);
}

// Ensures expensiveInit() is called exactly once across multiple threads.
// 确保 expensiveInit() is called exactly once across multiple threads.
// Uses a state machine with compare-and-swap to coordinate thread access.
// 使用 一个 state machine 使用 compare-和-swap 到 coordinate thread access.
fn callOnce() void {
    while (true) {
        // Check the current state with acquire semantics to see initialization results
        // 检查 当前 state 使用 acquire 语义 到 see initialization results
        switch (@atomicLoad(State, &once_state, .acquire)) {
            // Initialization complete, return immediately
            // Initialization complete, 返回 immediately
            .ready => return,
            // Another thread is initializing, yield and retry
            // Another thread is initializing, yield 和 retry
            .busy => {
                std.Thread.yield() catch {};
                continue;
            },
            // Not yet initialized, attempt to claim initialization responsibility
            // 不 yet initialized, 尝试 claim initialization responsibility
            .idle => {
                // Try to atomically transition from idle to busy
                // Try 到 atomically transition 从 idle 到 busy
                // If successful (returns null), this thread wins and will initialize
                // 如果 successful (返回 空), 此 thread wins 和 will initialize
                // If it fails (returns the actual value), another thread won, so retry
                // 如果 it fails (返回 actual 值), another thread won, so retry
                if (@cmpxchgStrong(State, &once_state, .idle, .busy, .acq_rel, .acquire)) |_| {
                    continue;
                }
                // This thread successfully claimed the initialization
                // 此 thread successfully claimed initialization
                break;
            },
        }
    }

    // Perform the one-time initialization
    // 执行 一个-time initialization
    expensiveInit();
    // Mark initialization as complete with release semantics
    // Mark initialization 作为 complete 使用 发布 语义
    @atomicStore(State, &once_state, .ready, .release);
}

// Arguments passed to each worker thread
// Arguments passed 到 每个 worker thread
const WorkerArgs = struct {
    results: []i32,
    index: usize,
};

// Worker thread function that calls the once-initialization and reads the result.
// Worker thread 函数 该 calls once-initialization 和 reads result.
fn worker(args: WorkerArgs) void {
    // Ensure initialization happens (blocks until complete if another thread is initializing)
    // 确保 initialization happens (代码块 until complete 如果 another thread is initializing)
    callOnce();
    // Read the initialized value with acquire semantics
    // 读取 initialized 值 使用 acquire 语义
    const value = @atomicLoad(i32, &config_value, .acquire);
    // Store the observed value in the thread's result slot
    // Store observed 值 在 thread's result slot
    args.results[args.index] = value;
}

pub fn main() !void {
    // Reset global state for demonstration
    // Reset global state 用于 demonstration
    once_state = .idle;
    config_value = 0;
    init_calls = 0;

    // Set up memory allocation
    // Set up 内存 allocation
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const worker_count: usize = 4;

    // Allocate array to collect results from each thread
    // 分配 数组 到 collect results 从 每个 thread
    const results = try allocator.alloc(i32, worker_count);
    defer allocator.free(results);
    // Initialize all result slots to -1 to detect if any thread fails
    // Initialize 所有 result slots 到 -1 到 detect 如果 any thread fails
    for (results) |*slot| slot.* = -1;

    // Allocate array to hold thread handles
    // 分配 数组 到 hold thread handles
    const threads = try allocator.alloc(std.Thread, worker_count);
    defer allocator.free(threads);

    // Spawn all worker threads
    // Spawn 所有 worker threads
    for (threads, 0..) |*thread, index| {
        thread.* = try std.Thread.spawn(.{}, worker, .{WorkerArgs{
            .results = results,
            .index = index,
        }});
    }

    // Wait for all threads to complete
    // Wait 用于 所有 threads 到 complete
    for (threads) |thread| {
        thread.join();
    }

    // Read final values after all threads complete
    // 读取 最终 值 after 所有 threads complete
    const final_value = @atomicLoad(i32, &config_value, .acquire);
    const called = @atomicLoad(u32, &init_calls, .seq_cst);

    // Set up buffered output
    // Set up 缓冲 输出
    var stdout_buffer: [256]u8 = undefined;
    var stdout_state = std.fs.File.stdout().writer(&stdout_buffer);
    const out = &stdout_state.interface;

    // Print the value observed by each thread (should all be 9157)
    // 打印 值 observed 通过 每个 thread (should 所有 be 9157)
    for (results, 0..) |value, index| {
        try out.print("thread {d} observed {d}\n", .{ index, value });
    }
    // Verify initialization was called exactly once
    try out.print("init calls: {d}\n", .{called});
    // Display the final configuration value
    // 显示 最终 configuration 值
    try out.print("config value: {d}\n", .{final_value});
    try out.flush();
}
