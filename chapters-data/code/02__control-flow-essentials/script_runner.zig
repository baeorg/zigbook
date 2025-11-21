// 文件路径: chapters-data/code/02__control-flow-essentials/script_runner.zig

// 演示高级控制流：switch表达式、带标签循环
// 和基于阈值条件的早期终止
const std = @import("std");

/// 脚本处理器中所有可能操作类型的枚举
const Action = enum { add, skip, threshold, unknown };

/// 表示单个处理步骤，包含相关操作和值
const Step = struct {
    tag: Action,
    value: i32,
};

/// 包含脚本执行完成或提前终止后的最终状态
const Outcome = struct {
    index: usize, // 处理停止的步骤索引
    total: i32,   // 终止时的累积总值
};

/// 将单字符代码映射到对应的Action枚举值
/// 对于无法识别的代码返回.unknown以保持穷举处理
fn mapCode(code: u8) Action {
    return switch (code) {
        'A' => .add,
        'S' => .skip,
        'T' => .threshold,
        else => .unknown,
    };
}

/// 执行步骤序列，累积值并检查阈值限制
/// 如果阈值步骤发现总值达到或超过限制，则提前停止处理
/// 返回包含停止索引和最终累积总值的Outcome
fn process(script: []const Step, limit: i32) Outcome {
    // 加法操作的运行累积器
    var total: i32 = 0;

    // for-else结构：break提供早期终止值，else提供完成值
    const stop = outer: for (script, 0..) |step, index| {
        // 根据当前步骤的操作类型分派
        switch (step.tag) {
            // 加法操作：将步骤的值累积到运行总值
            .add => total += step.value,
            // 跳过操作：绕过此步骤而不修改状态
            .skip => continue :outer,
            // 阈值检查：如果达到或超过限制则提前终止
            .threshold => {
                if (total >= limit) break :outer Outcome{ .index = index, .total = total };
                // 未达到阈值：继续下一步
                continue :outer;
            },
            // 安全断言：未知操作不应出现在已验证的脚本中
            .unknown => unreachable,
        }
    } else Outcome{ .index = script.len, .total = total }; // 所有步骤后正常完成

    return stop;
}

pub fn main() !void {
    // 定义演示所有操作类型的脚本序列
    const script = [_]Step{
        .{ .tag = mapCode('A'), .value = 2 },  // 加2 → 总计: 2
        .{ .tag = mapCode('S'), .value = 0 },  // 跳过（无效果）
        .{ .tag = mapCode('A'), .value = 5 },  // 加5 → 总计: 7
        .{ .tag = mapCode('T'), .value = 6 },  // 阈值检查 (7 >= 6: 触发早期退出)
        .{ .tag = mapCode('A'), .value = 10 }, // 由于早期终止而永不执行
    };

    // 使用阈值限制6执行脚本
    const outcome = process(&script, 6);

    // 报告执行停止的位置和最终累积值
    std.debug.print(
        "stopped at step {d} with total {d}\n",
        .{ outcome.index, outcome.total },
    );
}
