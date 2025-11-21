const std = @import("std");
const Order = std.math.Order;

// 表示带有SLA约束的传入支持请求。
const Request = struct {
    ticket: []const u8,
    submitted_at_ms: u64,
    sla_ms: u32,
    work_estimate_ms: u32,
    vip: bool,
};

// 调度策略参数，用于影响优先级决策。
const Policy = struct {
    now_ms: u64,             // 当前时间参考，用于计算松弛量
    vip_boost: i64,          // VIP请求的分数减少（加权）
    overdue_multiplier: i64, // 过期请求的惩罚倍数
};

// 计算请求的时间松弛量：正数表示剩余时间，负数表示已过期。
// 已过期的请求会根据策略的overdue_multiplier进行放大，以增加紧迫性。
fn slack(policy: Policy, request: Request) i64 {
    // 根据提交时间+SLA窗口计算绝对截止时间
    const deadline = request.submitted_at_ms + request.sla_ms;

    // 计算松弛量：deadline - now；使用i128防止减法溢出
    const slack_signed = @as(i64, @intCast(@as(i128, deadline) - @as(i128, policy.now_ms)));

    if (slack_signed >= 0) {
        // 正向松弛：请求仍在SLA内
        return slack_signed;
    }

    // 负向松弛：请求已过期；通过乘法放大紧迫性
    return slack_signed * policy.overdue_multiplier;
}

// 计算用于优先级的加权分数。
// 分数越低 = 优先级越高（由最小堆优先处理）。
fn weightedScore(policy: Policy, request: Request) i64 {
    // 从松弛量开始：负数（过期）或正数（剩余时间）
    var score = slack(policy, request);

    // 添加工作量估计：较长的任务优先级稍低（分数更高）
    score += @as(i64, @intCast(request.work_estimate_ms));

    // VIP加权：减少分数以提高优先级
    if (request.vip) score -= policy.vip_boost;

    return score;
}

// 优先级队列的比较函数。
// 如果'a'应该在'b'之前处理（分数越低优先级越高），则返回Order.lt。
fn requestOrder(policy: Policy, a: Request, b: Request) Order {
    const score_a = weightedScore(policy, a);
    const score_b = weightedScore(policy, b);
    return std.math.order(score_a, score_b);
}

// 通过将所有任务插入优先级队列来模拟调度场景，
// 然后按优先级顺序出队并打印。
fn simulateScenario(allocator: std.mem.Allocator, policy: Policy, label: []const u8) !void {
    // 定义一组具有不同SLA约束和特性的传入请求
    const tasks = [_]Request{
        .{ .ticket = "INC-482", .submitted_at_ms = 0, .sla_ms = 500, .work_estimate_ms = 120, .vip = false },
        .{ .ticket = "INC-993", .submitted_at_ms = 120, .sla_ms = 400, .work_estimate_ms = 60, .vip = true },
        .{ .ticket = "INC-511", .submitted_at_ms = 200, .sla_ms = 200, .work_estimate_ms = 45, .vip = false },
        .{ .ticket = "INC-742", .submitted_at_ms = 340, .sla_ms = 120, .work_estimate_ms = 30, .vip = false },
    };

    // 使用给定策略作为比较上下文初始化优先级队列
    var queue = std.PriorityQueue(Request, Policy, requestOrder).init(allocator, policy);
    defer queue.deinit();

    // 将所有任务添加到队列中；它们将自动按堆排序
    try queue.addSlice(&tasks);

    // 打印场景标题
    std.debug.print("{s} (now={d}ms)\n", .{ label, policy.now_ms });

    // 按优先级顺序出队并打印请求（分数最低的优先）
    while (queue.removeOrNull()) |request| {
        // 重新计算分数和截止时间用于显示
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
    // 设置通用分配器并启用泄漏检测
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // 场景1：中班时段，适度VIP加权且有逾期惩罚
    try simulateScenario(
        allocator,
        .{ .now_ms = 350, .vip_boost = 250, .overdue_multiplier = 2 },
        "Mid-shift triage"
    );

    // 场景2：升级窗口，VIP加权降低但过期惩罚更高
    try simulateScenario(
        allocator,
        .{ .now_ms = 520, .vip_boost = 100, .overdue_multiplier = 4 },
        "Escalation window"
    );
}
