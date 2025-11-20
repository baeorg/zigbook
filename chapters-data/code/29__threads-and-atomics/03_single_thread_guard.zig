const std = @import("std");
const builtin = @import("builtin");

// Enum representing the possible states of task execution
// Enum representing possible states 的 task execution
// Uses explicit u8 backing to ensure consistent size across platforms
// 使用 explicit u8 backing 到 确保 consistent size across platforms
const TaskState = enum(u8) { idle, threaded_done, inline_done };

// Global atomic state tracking whether task ran inline or in a separate thread
// Global 原子 state tracking whether task ran inline 或 在 一个 separate thread
// Atomics ensure thread-safe access even though single-threaded builds won't spawn threads
// Atomics 确保 thread-安全 access even though single-threaded builds won't spawn threads
var task_state = std.atomic.Value(TaskState).init(.idle);

// Simulates a task that runs in a separate thread
// Simulates 一个 task 该 runs 在 一个 separate thread
// Includes a small delay to demonstrate asynchronous execution
// Includes 一个 small delay 到 demonstrate asynchronous execution
fn threadedTask() void {
    std.Thread.sleep(1 * std.time.ns_per_ms);
    // Release ordering ensures all prior writes are visible to threads that acquire this value
    // 发布 ordering 确保 所有 prior writes are visible 到 threads 该 acquire 此 值
    task_state.store(.threaded_done, .release);
}

// Simulates a task that runs inline in the main thread
// Simulates 一个 task 该 runs inline 在 主 thread
// Used as fallback when threading is disabled at compile time
// Used 作为 fallback 当 threading is disabled 在 编译时
fn inlineTask() void {
    // Release ordering maintains consistency with the threaded path
    // 发布 ordering maintains consistency 使用 threaded 路径
    task_state.store(.inline_done, .release);
}

pub fn main() !void {
    // Set up buffered stdout writer for efficient output
    // Set up 缓冲 stdout writer 用于 efficient 输出
    var stdout_buffer: [256]u8 = undefined;
    var stdout_state = std.fs.File.stdout().writer(&stdout_buffer);
    const out = &stdout_state.interface;

    // Reset state to idle with sequential consistency
    // Reset state 到 idle 使用 sequential consistency
    // seq_cst provides strongest ordering guarantees for initialization
    // seq_cst provides strongest ordering guarantees 用于 initialization
    task_state.store(.idle, .seq_cst);

    // Check compile-time flag to determine execution strategy
    // 检查 编译-time flag 到 确定 execution strategy
    // builtin.single_threaded is true when compiled with -fsingle-threaded
    // 内置.single_threaded is true 当 compiled 使用 -fsingle-threaded
    if (builtin.single_threaded) {
        try out.print("single-threaded build; running task inline\n", .{});
        // Execute task directly without spawning a thread
        // Execute task directly without spawning 一个 thread
        inlineTask();
    } else {
        try out.print("multi-threaded build; spawning worker\n", .{});
        // Spawn separate thread to execute task concurrently
        // Spawn separate thread 到 execute task concurrently
        var worker = try std.Thread.spawn(.{}, threadedTask, .{});
        // Block until worker thread completes
        worker.join();
    }

    // Acquire ordering ensures we observe all writes made before the release store
    // Acquire ordering 确保 we observe 所有 writes made before 发布 store
    const final_state = task_state.load(.acquire);
    
    // Convert enum state to human-readable string for output
    // Convert enum state 到 human-readable string 用于 输出
    const label = switch (final_state) {
        .idle => "idle",
        .threaded_done => "threaded_done",
        .inline_done => "inline_done",
    };

    // Display final execution state and flush buffer to ensure output is visible
    // 显示 最终 execution state 和 刷新 缓冲区 到 确保 输出 is visible
    try out.print("task state: {s}\n", .{label});
    try out.flush();
}
