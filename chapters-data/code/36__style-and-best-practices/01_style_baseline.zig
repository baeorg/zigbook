const std = @import("std");

// 统计计算失败的错误集合
// 故意设置得狭窄精确，以便调用者进行精确的错误处理
pub const StatsError = error{EmptyInput};

// 日志操作的组合错误集合
// 将统计错误与输出格式化失败合并
pub const LogError = StatsError || error{OutputTooSmall};

/// 计算提供样本的算术平均值
/// Parameters:
/// 参数:
///   - `samples`: 从测量系列中收集的 `f64` 值切片
///
/// 当 `samples` 为空时，返回平均值作为 `f64` 或 `StatsError.EmptyInput`
pub fn mean(samples: []const f64) StatsError!f64 {
    // 防止除以零；对空输入返回特定域错误
    if (samples.len == 0) return StatsError.EmptyInput;

    // 累加所有样本值的总和
    var total: f64 = 0.0;
    for (samples) |value| {
        total += value;
    }
    
    // 将样本计数转换为浮点数以进行精确除法
    const count = @as(f64, @floatFromInt(samples.len));
    return total / count;
}

/// 计算平均值并使用提供的写入器打印结果 
// / Accepts any writer type that conforms to the standard writer interface,
/// 接受任何符合标准写入器接口的写入器类型，
/// 支持灵活的输出目标（文件、缓冲区、套接字）
pub fn logMean(writer: anytype, samples: []const f64) LogError!void {
    // 将计算委托给 mean()；传播任何统计错误
    const value = try mean(samples);
    
    // 尝试格式化并写入结果；捕获写入器特定的失败
    writer.print("mean = {d:.3}\n", .{value}) catch {
        // 将不透明的写入器错误转换为我们的特定域错误集合
        return error.OutputTooSmall;
    };
}

/// 用于比较浮点值的辅助函数（带容差）
/// 包装 std.math.approxEqAbs 以与测试错误处理无缝协作
fn assertApproxEqual(expected: f64, actual: f64, tolerance: f64) !void {
    try std.testing.expect(std.math.approxEqAbs(f64, expected, actual, tolerance));
}

test "mean handles positive numbers" {
    // 验证 [2.0, 3.0, 4.0] 的平均值在浮点容差范围内等于 3.0
    try assertApproxEqual(3.0, try mean(&[_]f64{ 2.0, 3.0, 4.0 }), 0.001);
}

test "mean returns error on empty input" {
    // 确认空切片会触发预期的域错误
    try std.testing.expectError(StatsError.EmptyInput, mean(&[_]f64{}));
}

test "logMean forwards formatted output" {
    // 分配固定大小的缓冲区以捕获写入的输出
    var storage: [128]u8 = undefined;
    var stream = std.io.fixedBufferStream(&storage);

    // 将平均值结果写入内存缓冲区
    try logMean(stream.writer(), &[_]f64{ 1.0, 2.0, 3.0 });
    
    // 获取写入的内容并验证其包含预期的标签
    const rendered = stream.getWritten();
    try std.testing.expect(std.mem.containsAtLeast(u8, rendered, 1, "mean"));
}
