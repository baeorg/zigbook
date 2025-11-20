// / Demo: Using std.PriorityQueue to dispatch tasks by priority.
// / Demo: 使用 std.PriorityQueue 到 dispatch tasks 通过 priority.
// / Lower urgency values mean higher priority; ties are broken by earlier submission time.
// / Lower urgency 值 mean higher priority; ties are broken 通过 earlier submission time.
// / This example prints the order in which tasks would be processed.
// / 此 示例 prints order 在 which tasks would be processed.
///
/// Notes:
// / - The comparator returns `.lt` when `a` should be dispatched before `b`.
// / - comparator 返回 `.lt` 当 `一个` should be dispatched before `b`.
// / - We also order by `submitted_at_ms` to ensure deterministic order among equal urgencies.
// / - We also order 通过 `submitted_at_ms` 到 确保 deterministic order among equal urgencies.
const std = @import("std");
const Order = std.math.Order;

// / A single work item to schedule.
// / 一个 single work item 到 schedule.
const Task = struct {
    // / Display name for the task.
    // / 显示 name 用于 task.
    name: []const u8,
    // / Priority indicator: lower value = more urgent.
    // / Priority indicator: lower 值 = more urgent.
    urgency: u8,
    // / Monotonic timestamp in milliseconds used to break ties (earlier wins).
    // / Monotonic timestamp 在 milliseconds used 到 break ties (earlier wins).
    submitted_at_ms: u64,
};

// / Comparator for the priority queue:
// / Comparator 用于 priority queue:
// / - Primary key: urgency (lower is dispatched first)
// / - Primary key: urgency (lower is dispatched 首先)
// / - Secondary key: submitted_at_ms (earlier is dispatched first)
// / - Secondary key: submitted_at_ms (earlier is dispatched 首先)
fn taskOrder(_: void, a: Task, b: Task) Order {
    // Compare by urgency first.
    // Compare 通过 urgency 首先.
    if (a.urgency < b.urgency) return .lt;
    if (a.urgency > b.urgency) return .gt;

    // Tie-breaker: earlier submission is higher priority.
    return std.math.order(a.submitted_at_ms, b.submitted_at_ms);
}

// / Program entry: builds a priority queue and prints dispatch order.
// / Program entry: builds 一个 priority queue 和 prints dispatch order.
pub fn main() !void {
    // Use the General Purpose Allocator (GPA) for simplicity in examples.
    // Use General Purpose Allocator (GPA) 用于 simplicity 在 示例.
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Instantiate a priority queue of Task:
    // Instantiate 一个 priority queue 的 Task:
    // - Context type is `void` (no extra state needed by the comparator)
    // - Context 类型 is `void` (不 extra state needed 通过 comparator)
    // - `taskOrder` defines the ordering.
    // - `taskOrder` defines ordering.
    var queue = std.PriorityQueue(Task, void, taskOrder).init(allocator, {});
    defer queue.deinit();

    // Enqueue tasks with varying urgency and submission times.
    // Enqueue tasks 使用 varying urgency 和 submission times.
    // Expectation (by our ordering): lower urgency processed first;
    // Expectation (通过 our ordering): lower urgency processed 首先;
    // within same urgency, earlier submitted_at_ms processed first.
    // within same urgency, earlier submitted_at_ms processed 首先.
    try queue.add(.{ .name = "compile pointer.zig", .urgency = 0, .submitted_at_ms = 1 });
    try queue.add(.{ .name = "run tests", .urgency = 1, .submitted_at_ms = 2 });
    try queue.add(.{ .name = "deploy preview", .urgency = 2, .submitted_at_ms = 3 });
    try queue.add(.{ .name = "prepare changelog", .urgency = 1, .submitted_at_ms = 4 });

    std.debug.print("Dispatch order:\n", .{});

    // Remove tasks in priority order until the queue is empty.
    // Remove tasks 在 priority order until queue is 空.
    // removeOrNull() yields the next Task or null when empty.
    // removeOrNull() yields 下一个 Task 或 空 当 空.
    while (queue.removeOrNull()) |task| {
        std.debug.print("  - {s} (urgency {d})\n", .{ task.name, task.urgency });
    }
}
