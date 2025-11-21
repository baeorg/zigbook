const std = @import("std");
const builtin = @import("builtin");

// Enum representing the possible states of task execution
// 表示任务执行可能状态的枚举
// Uses explicit u8 backing to ensure consistent size across platforms
// 使用显式 u8 后备以确保跨平台一致的大小
const TaskState = enum(u8) { idle, threaded_done, inline_done };

// Global atomic state tracking whether task ran inline or in a separate thread
// 全局原子状态跟踪任务是内联运行还是在单独线程中运行
// Atomics ensure thread-safe access even though single-threaded builds won't spawn threads
// 原子操作确保线程安全访问，即使单线程构建不会生成线程
var task_state = std.atomic.Value(TaskState).init(.idle);

// Simulates a task that runs in a separate thread
// 模拟在单独线程中运行的任务
// Includes a small delay to demonstrate asynchronous execution
// 包括一个小延迟来演示异步执行
fn threadedTask() void {
    std.Thread.sleep(1 * std.time.ns_per_ms);
    // Release ordering ensures all prior writes are visible to threads that acquire this value
    // 发布排序确保获取此值的所有线程都能看到之前的写入
    task_state.store(.threaded_done, .release);
}

// Simulates a task that runs inline in the main thread
// 模拟在主线程内联运行的任务
// Used as fallback when threading is disabled at compile time
// 用作编译时禁用线程时的后备方案
fn inlineTask() void {
    // Release ordering maintains consistency with the threaded path
    // 发布排序保持与线程路径的一致性
    task_state.store(.inline_done, .release);
}

pub fn main() !void {
    // Set up buffered stdout writer for efficient output
    // 为高效输出设置缓冲 stdout 写入器
    var stdout_buffer: [256]u8 = undefined;
    var stdout_state = std.fs.File.stdout().writer(&stdout_buffer);
    const out = &stdout_state.interface;

    // Reset state to idle with sequential consistency
    // 使用顺序一致性重置状态为空闲
    // seq_cst provides strongest ordering guarantees for initialization
    // seq_cst 为初始化提供最强的排序保证
    task_state.store(.idle, .seq_cst);

    // Check compile-time flag to determine execution strategy
    // 检查编译时标志以确定执行策略
    // builtin.single_threaded is true when compiled with -fsingle-threaded
    // 当使用 -fsingle-threaded 编译时，内置.single_threaded 为 true
    if (builtin.single_threaded) {
        try out.print("single-threaded build; running task inline\n", .{});
        // Execute task directly without spawning a thread
        // 直接执行任务而不生成线程
        inlineTask();
    } else {
        try out.print("multi-threaded build; spawning worker\n", .{});
        // Spawn separate thread to execute task concurrently
        // 生成单独线程以并发执行任务
        var worker = try std.Thread.spawn(.{}, threadedTask, .{});
        // Block until worker thread completes
        worker.join();
    }

    // Acquire ordering ensures we observe all writes made before the release store
    // 获取排序确保我们观察到发布存储之前的所有写入
    const final_state = task_state.load(.acquire);
    
    // Convert enum state to human-readable string for output
    // 将枚举状态转换为人类可读的字符串用于输出
    const label = switch (final_state) {
        .idle => "idle",
        .threaded_done => "threaded_done",
        .inline_done => "inline_done",
    };

    // Display final execution state and flush buffer to ensure output is visible
    // 显示最终执行状态并刷新缓冲区以确保输出可见
    try out.print("task state: {s}\n", .{label});
    try out.flush();
}
