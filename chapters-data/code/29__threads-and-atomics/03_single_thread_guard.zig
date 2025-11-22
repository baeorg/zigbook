const std = @import("std");
const builtin = @import("builtin");

// 表示任务执行可能状态的枚举
// 使用显式 u8 后备以确保跨平台一致的大小
const TaskState = enum(u8) { idle, threaded_done, inline_done };

// 全局原子状态跟踪任务是内联运行还是在单独线程中运行
// 原子操作确保线程安全访问，即使单线程构建不会生成线程
var task_state = std.atomic.Value(TaskState).init(.idle);

// 模拟在单独线程中运行的任务
// 包括一个小延迟来演示异步执行
fn threadedTask() void {
    std.Thread.sleep(1 * std.time.ns_per_ms);
    // 发布排序确保获取此值的所有线程都能看到之前的写入
    task_state.store(.threaded_done, .release);
}

// 模拟在主线程内联运行的任务
// 用作编译时禁用线程时的后备方案
fn inlineTask() void {
    // 发布排序保持与线程路径的一致性
    task_state.store(.inline_done, .release);
}

pub fn main() !void {
    // 为高效输出设置缓冲标准输出写入器
    var stdout_buffer: [256]u8 = undefined;
    var stdout_state = std.fs.File.stdout().writer(&stdout_buffer);
    const out = &stdout_state.interface;

    // 使用顺序一致性重置状态为空闲
    // seq_cst 为初始化提供最强的排序保证
    task_state.store(.idle, .seq_cst);

    // 检查编译时标志以确定执行策略
    // 当使用 -fsingle-threaded 编译时，builtin.single_threaded 为 true
    if (builtin.single_threaded) {
        try out.print("single-threaded build; running task inline\n", .{});
        // 直接执行任务而不生成线程
        inlineTask();
    } else {
        try out.print("multi-threaded build; spawning worker\n", .{});
        // 生成单独线程以并发执行任务
        var worker = try std.Thread.spawn(.{}, threadedTask, .{});
        // 阻塞直到工作线程完成
        worker.join();
    }

    // 获取排序确保我们观察到发布存储之前的所有写入
    const final_state = task_state.load(.acquire);
    
    // 将枚举状态转换为人类可读的字符串用于输出
    const label = switch (final_state) {
        .idle => "idle",
        .threaded_done => "threaded_done",
        .inline_done => "inline_done",
    };

    // 显示最终执行状态并刷新缓冲区以确保输出可见
    try out.print("task state: {s}\n", .{label});
    try out.flush();
}
