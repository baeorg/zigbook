// ! Style baseline example demonstrating naming, documentation, and tests.
// ! Style baseline 示例 demonstrating naming, 文档, 和 tests.

const std = @import("std");

// / Error set for statistical computation failures.
// / 错误集合 用于 statistical computation failures.
// / Intentionally narrow to allow precise error handling by callers.
// / Intentionally narrow 到 allow precise 错误处理 通过 callers.
pub const StatsError = error{EmptyInput};

// / Combined error set for logging operations.
// / Combined 错误集合 用于 logging operations.
// / Merges statistical errors with output formatting failures.
// / Merges statistical 错误 使用 输出 formatting failures.
pub const LogError = StatsError || error{OutputTooSmall};

// / Calculates the arithmetic mean of the provided samples.
// / Calculates arithmetic mean 的 provided 样本.
///
/// Parameters:
// /  - `samples`: slice of `f64` values collected from a measurement series.
// / - `样本`: 切片 的 `f64` 值 collected 从 一个 measurement series.
///
// / Returns the mean as `f64` or `StatsError.EmptyInput` when `samples` is empty.
// / 返回 mean 作为 `f64` 或 `StatsError.EmptyInput` 当 `样本` is 空.
pub fn mean(samples: []const f64) StatsError!f64 {
    // Guard against division by zero; return domain-specific error for empty input
    // Guard against division 通过 零; 返回 domain-specific 错误 用于 空 输入
    if (samples.len == 0) return StatsError.EmptyInput;

    // Accumulate the sum of all sample values
    // Accumulate sum 的 所有 sample 值
    var total: f64 = 0.0;
    for (samples) |value| {
        total += value;
    }
    
    // Convert sample count to floating-point for precise division
    // Convert sample count 到 floating-point 用于 precise division
    const count = @as(f64, @floatFromInt(samples.len));
    return total / count;
}

// / Computes the mean and prints the result using the supplied writer.
// / Computes mean 和 prints result 使用 supplied writer.
/// 
// / Accepts any writer type that conforms to the standard writer interface,
// / Accepts any writer 类型 该 conforms 到 标准 writer 接口,
// / enabling flexible output destinations (files, buffers, sockets).
// / enabling flexible 输出 destinations (文件, buffers, sockets).
pub fn logMean(writer: anytype, samples: []const f64) LogError!void {
    // Delegate computation to mean(); propagate any statistical errors
    // Delegate computation 到 mean(); propagate any statistical 错误
    const value = try mean(samples);
    
    // Attempt to format and write result; catch writer-specific failures
    // 尝试 format 和 写入 result; 捕获 writer-specific failures
    writer.print("mean = {d:.3}\n", .{value}) catch {
        // Translate opaque writer errors into our domain-specific error set
        // Translate opaque writer 错误 into our domain-specific 错误集合
        return error.OutputTooSmall;
    };
}

// / Helper for comparing floating-point values with tolerance.
// / Helper 用于 comparing floating-point 值 使用 tolerance.
// / Wraps std.math.approxEqAbs to work seamlessly with test error handling.
// / Wraps std.math.approxEqAbs 到 work seamlessly 使用 test 错误处理.
fn assertApproxEqual(expected: f64, actual: f64, tolerance: f64) !void {
    try std.testing.expect(std.math.approxEqAbs(f64, expected, actual, tolerance));
}

test "mean handles positive numbers" {
    // Verify mean of [2.0, 3.0, 4.0] equals 3.0 within floating-point tolerance
    // Verify mean 的 [2.0, 3.0, 4.0] equals 3.0 within floating-point tolerance
    try assertApproxEqual(3.0, try mean(&[_]f64{ 2.0, 3.0, 4.0 }), 0.001);
}

test "mean returns error on empty input" {
    // Confirm that an empty slice triggers the expected domain error
    // Confirm 该 一个 空 切片 triggers expected domain 错误
    try std.testing.expectError(StatsError.EmptyInput, mean(&[_]f64{}));
}

test "logMean forwards formatted output" {
    // Allocate a fixed buffer to capture written output
    // 分配 一个 fixed 缓冲区 到 捕获 written 输出
    var storage: [128]u8 = undefined;
    var stream = std.io.fixedBufferStream(&storage);

    // Write mean result to the in-memory buffer
    // 写入 mean result 到 在-内存 缓冲区
    try logMean(stream.writer(), &[_]f64{ 1.0, 2.0, 3.0 });
    
    // Retrieve what was written and verify it contains the expected label
    // Retrieve what was written 和 verify it contains expected 标签
    const rendered = stream.getWritten();
    try std.testing.expect(std.mem.containsAtLeast(u8, rendered, 1, "mean"));
}
