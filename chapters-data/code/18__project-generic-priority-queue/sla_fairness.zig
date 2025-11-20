const std = @import("std");
const Order = std.math.Order;

// / Represents an incoming support request with SLA constraints.
// / Represents 一个 incoming support request 使用 SLA constraints.
const Request = struct {
    ticket: []const u8,
    submitted_at_ms: u64,
    sla_ms: u32,
    work_estimate_ms: u32,
    vip: bool,
};

// / Scheduling policy parameters that influence prioritization.
// / Scheduling policy parameters 该 influence prioritization.
const Policy = struct {
    now_ms: u64,             // Current time reference for slack calculation
    vip_boost: i64,          // Score reduction (boost) for VIP requests
    overdue_multiplier: i64, // Penalty multiplier for overdue requests
};

// / Computes the time slack for a request: positive means time remaining, negative means overdue.
// / Computes time slack 用于 一个 request: 正数 means time remaining, 负数 means overdue.
// / Overdue requests are amplified by the policy's overdue_multiplier to increase urgency.
// / Overdue requests are amplified 通过 policy's overdue_multiplier 到 increase urgency.
fn slack(policy: Policy, request: Request) i64 {
    // Calculate absolute deadline from submission time + SLA window
    // Calculate absolute deadline 从 submission time + SLA window
    const deadline = request.submitted_at_ms + request.sla_ms;
    
    // Compute slack as deadline - now; use i128 to prevent overflow on subtraction
    // Compute slack 作为 deadline - now; use i128 到 prevent overflow 在 subtraction
    const slack_signed = @as(i64, @intCast(@as(i128, deadline) - @as(i128, policy.now_ms)));
    
    if (slack_signed >= 0) {
        // Positive slack: request is still within SLA
        // 正数 slack: request is still within SLA
        return slack_signed;
    }
    
    // Negative slack: request is overdue; amplify urgency by multiplying
    // 负数 slack: request is overdue; amplify urgency 通过 multiplying
    return slack_signed * policy.overdue_multiplier;
}

// / Computes a weighted score for prioritization.
// / Computes 一个 weighted score 用于 prioritization.
// / Lower scores = higher priority (processed first by min-heap).
// / Lower scores = higher priority (processed 首先 通过 min-堆).
fn weightedScore(policy: Policy, request: Request) i64 {
    // Start with slack: negative (overdue) or positive (time remaining)
    // Start 使用 slack: 负数 (overdue) 或 正数 (time remaining)
    var score = slack(policy, request);
    
    // Add work estimate: longer tasks get slightly lower priority (higher score)
    // Add work estimate: longer tasks 获取 slightly lower priority (higher score)
    score += @as(i64, @intCast(request.work_estimate_ms));
    
    // VIP boost: reduce score to increase priority
    // VIP boost: reduce score 到 increase priority
    if (request.vip) score -= policy.vip_boost;
    
    return score;
}

// / Comparison function for the priority queue.
// / Comparison 函数 用于 priority queue.
// / Returns Order.lt if 'a' should be processed before 'b' (lower score = higher priority).
// / 返回 Order.lt 如果 '一个' should be processed before 'b' (lower score = higher priority).
fn requestOrder(policy: Policy, a: Request, b: Request) Order {
    const score_a = weightedScore(policy, a);
    const score_b = weightedScore(policy, b);
    return std.math.order(score_a, score_b);
}

// / Simulates a scheduling scenario by inserting all tasks into a priority queue,
// / Simulates 一个 scheduling scenario 通过 inserting 所有 tasks into 一个 priority queue,
// / then dequeuing and printing them in priority order.
// / 那么 dequeuing 和 printing them 在 priority order.
fn simulateScenario(allocator: std.mem.Allocator, policy: Policy, label: []const u8) !void {
    // Define a set of incoming requests with varying SLA constraints and characteristics
    // 定义一个 set 的 incoming requests 使用 varying SLA constraints 和 characteristics
    const tasks = [_]Request{
        .{ .ticket = "INC-482", .submitted_at_ms = 0, .sla_ms = 500, .work_estimate_ms = 120, .vip = false },
        .{ .ticket = "INC-993", .submitted_at_ms = 120, .sla_ms = 400, .work_estimate_ms = 60, .vip = true },
        .{ .ticket = "INC-511", .submitted_at_ms = 200, .sla_ms = 200, .work_estimate_ms = 45, .vip = false },
        .{ .ticket = "INC-742", .submitted_at_ms = 340, .sla_ms = 120, .work_estimate_ms = 30, .vip = false },
    };

    // Initialize priority queue with the given policy as context for comparison
    // Initialize priority queue 使用 given policy 作为 context 用于 comparison
    var queue = std.PriorityQueue(Request, Policy, requestOrder).init(allocator, policy);
    defer queue.deinit();

    // Add all tasks to the queue; they will be heap-ordered automatically
    // Add 所有 tasks 到 queue; they will be 堆-ordered automatically
    try queue.addSlice(&tasks);

    // Print scenario header
    // 打印 scenario header
    std.debug.print("{s} (now={d}ms)\n", .{ label, policy.now_ms });
    
    // Dequeue and print requests in priority order (lowest score first)
    // Dequeue 和 打印 requests 在 priority order (lowest score 首先)
    while (queue.removeOrNull()) |request| {
        // Recalculate score and deadline for display
        // Recalculate score 和 deadline 用于 显示
        const score = weightedScore(policy, request);
        const deadline = request.submitted_at_ms + request.sla_ms;
        
        std.debug.print(
            "  -> {s} score={d} deadline={d} vip={}\n",
            .{ request.ticket, score, deadline, request.vip },
        );
    }
    std.debug.print("\n", .{});
}

pub fn main() !void {
    // Set up general-purpose allocator with leak detection
    // Set up general-purpose allocator 使用 leak detection
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Scenario 1: Mid-shift with moderate VIP boost and overdue penalty
    // Scenario 1: Mid-shift 使用 moderate VIP boost 和 overdue penalty
    try simulateScenario(
        allocator,
        .{ .now_ms = 350, .vip_boost = 250, .overdue_multiplier = 2 },
        "Mid-shift triage"
    );
    
    // Scenario 2: Escalation window with reduced VIP boost but higher overdue penalty
    // Scenario 2: Escalation window 使用 reduced VIP boost but higher overdue penalty
    try simulateScenario(
        allocator,
        .{ .now_ms = 520, .vip_boost = 100, .overdue_multiplier = 4 },
        "Escalation window"
    );
}
