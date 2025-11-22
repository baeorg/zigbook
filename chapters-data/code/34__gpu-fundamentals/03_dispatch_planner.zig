// ! GPU 调度规划工具
//!
// ! 该模块演示了如何计算 GPU 计算着色器的工作组调度参数。
// ! 它展示了总工作项、工作组大小和由此产生的调度
// ! 配置之间的关系，包括处理未填满完整工作组的“尾部”元素。

const std = @import("std");

// / 表示用于并行执行的完整调度配置
// / 包含启动计算内核或并行任务所需的所有参数
const DispatchPlan = struct {
    // / 每个工作组的大小（每组的线程/调用数）
    workgroup_size: u32,
    // / 覆盖所有项目所需的工作组数量
    group_count: u32,
    // / 包括填充在内的总调用次数（始终是 workgroup_size 的倍数）
    padded_invocations: u32,
    // / 最后一个工作组中填充/未使用的调用次数
    tail: u32,
};

// / 为给定的问题大小和工作组配置计算最佳调度参数
///
// / 计算处理所有项目所需的工作组数量，考虑到
// / 最后一个工作组可能部分填充的事实。这对于 GPU 计算着色器至关重要，
// / 其中工作必须以工作组大小的倍数进行调度。
fn computeDispatch(total_items: u32, workgroup_size: u32) DispatchPlan {
    // 确保工作组大小有效（GPU 工作组不能为空）
    std.debug.assert(workgroup_size > 0);

    // 计算所需工作组的数量，向上取整以确保所有项目都被覆盖
    const groups = std.math.divCeil(u32, total_items, workgroup_size) catch unreachable;

    // 计算包括填充在内的总调用次数（GPU 总是启动完整的工作组）
    const padded = groups * workgroup_size;

    return .{
        .workgroup_size = workgroup_size,
        .group_count = groups,
        .padded_invocations = padded,
        // 尾部表示必须通过边界检查处理的浪费的调用
        .tail = padded - total_items,
    };
}

// / 使用相同的调度逻辑模拟 CPU 侧并行执行规划
///
// / 演示了工作组调度公式同样适用于 CPU 线程批处理，
// / 确保 GPU 和 CPU 回退实现之间的一致行为。
fn simulateCpuFallback(total_items: u32, lanes: u32) DispatchPlan {
    // 重用 GPU 公式，使主机侧分块与设备调度匹配。
    return computeDispatch(total_items, lanes);
}

pub fn main() !void {
    // 定义一个示例问题：处理 1000 个项目
    const problem_size: u32 = 1000;

    // 典型的 GPU 工作组大小（通常为 32、64 或 256，取决于硬件）
    const workgroup_size: u32 = 64;

    // 计算 GPU 调度配置
    const plan = computeDispatch(problem_size, workgroup_size);
    std.debug.print(
        "gpu dispatch: {d} groups × {d} lanes => {d} invocations (tail {d})\n",
        .{ plan.group_count, plan.workgroup_size, plan.padded_invocations, plan.tail },
    );

    // 模拟 CPU 回退，并行通道更少
    const fallback_threads: u32 = 16;
    const cpu = simulateCpuFallback(problem_size, fallback_threads);
    std.debug.print(
        "cpu chunks: {d} batches × {d} lanes => {d} logical tasks (tail {d})\n",
        .{ cpu.group_count, cpu.workgroup_size, cpu.padded_invocations, cpu.tail },
    );
}
