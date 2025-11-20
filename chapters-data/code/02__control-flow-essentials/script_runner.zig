// File: chapters-data/code/02__control-flow-essentials/script_runner.zig

// Demonstrates advanced control flow: switch expressions, labeled loops,
// 演示 advanced 控制流: switch expressions, labeled loops,
// and early termination based on threshold conditions
// 和 early termination 基于 threshold conditions
const std = @import("std");

// / Enumeration of all possible action types in the script processor
// / Enumeration 的 所有 possible action 类型 在 script processor
const Action = enum { add, skip, threshold, unknown };

// / Represents a single processing step with an associated action and value
// / Represents 一个 single processing step 使用 一个 associated action 和 值
const Step = struct {
    tag: Action,
    value: i32,
};

// / Contains the final state after script execution completes or terminates early
// / Contains 最终 state after script execution completes 或 terminates early
const Outcome = struct {
    index: usize, // Step index where processing stopped
    total: i32,   // Accumulated total at termination
};

// / Maps single-character codes to their corresponding Action enum values.
// / Maps single-character codes 到 their 对应的 Action enum 值.
// / Returns .unknown for unrecognized codes to maintain exhaustive handling.
// / 返回 .unknown 用于 unrecognized codes 到 maintain exhaustive handling.
fn mapCode(code: u8) Action {
    return switch (code) {
        'A' => .add,
        'S' => .skip,
        'T' => .threshold,
        else => .unknown,
    };
}

// / Executes a sequence of steps, accumulating values and checking threshold limits.
// / Executes 一个 sequence 的 steps, accumulating 值 和 checking threshold limits.
// / Processing stops early if a threshold step finds the total meets or exceeds the limit.
// / Processing stops early 如果 一个 threshold step finds total meets 或 exceeds limit.
// / Returns an Outcome containing the stop index and final accumulated total.
// / 返回 一个 Outcome containing stop 索引 和 最终 accumulated total.
fn process(script: []const Step, limit: i32) Outcome {
    // Running accumulator for add operations
    // Running accumulator 用于 add operations
    var total: i32 = 0;

    // for-else construct: break provides early termination value, else provides completion value
    // 用于-否则 construct: break provides early termination 值, 否则 provides completion 值
    const stop = outer: for (script, 0..) |step, index| {
        // Dispatch based on the current step's action type
        // Dispatch 基于 当前 step's action 类型
        switch (step.tag) {
            // Add operation: accumulate the step's value to the running total
            // Add operation: accumulate step's 值 到 running total
            .add => total += step.value,
            // Skip operation: bypass this step without modifying state
            // Skip operation: bypass 此 step without modifying state
            .skip => continue :outer,
            // Threshold check: terminate early if limit is reached or exceeded
            // Threshold 检查: terminate early 如果 limit is reached 或 exceeded
            .threshold => {
                if (total >= limit) break :outer Outcome{ .index = index, .total = total };
                // Threshold not met: continue to next step
                // Threshold 不 met: continue 到 下一个 step
                continue :outer;
            },
            // Safety assertion: unknown actions should never appear in validated scripts
            // Safety assertion: unknown actions should never appear 在 validated scripts
            .unknown => unreachable,
        }
    } else Outcome{ .index = script.len, .total = total }; // Normal completion after all steps

    return stop;
}

pub fn main() !void {
    // Define a script sequence demonstrating all action types
    // 定义一个 script sequence demonstrating 所有 action 类型
    const script = [_]Step{
        .{ .tag = mapCode('A'), .value = 2 },  // Add 2 → total: 2
        .{ .tag = mapCode('S'), .value = 0 },  // Skip (no effect)
        .{ .tag = mapCode('A'), .value = 5 },  // Add 5 → total: 7
        .{ .tag = mapCode('T'), .value = 6 },  // Threshold check (7 >= 6: triggers early exit)
        .{ .tag = mapCode('A'), .value = 10 }, // Never executed due to early termination
    };

    // Execute the script with a threshold limit of 6
    // Execute script 使用 一个 threshold limit 的 6
    const outcome = process(&script, 6);
    
    // Report where execution stopped and the final accumulated value
    // Report where execution stopped 和 最终 accumulated 值
    std.debug.print(
        "stopped at step {d} with total {d}\n",
        .{ outcome.index, outcome.total },
    );
}
