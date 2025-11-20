
// Analytics library for statistical calculations on metrics
// Analytics 库 用于 statistical calculations 在 metrics
const std = @import("std");

// Represents a named metric with associated numerical values
// Represents 一个 named metric 使用 associated numerical 值
pub const Metric = struct {
    name: []const u8,
    values: []const f64,
};

// Calculates the arithmetic mean (average) of all values in a metric
// Calculates arithmetic mean (average) 的 所有 值 在 一个 metric
// Returns the sum of all values divided by the count
// 返回 sum 的 所有 值 divided 通过 count
pub fn mean(metric: Metric) f64 {
    var total: f64 = 0;
    for (metric.values) |value| {
        total += value;
    }
    return total / @as(f64, @floatFromInt(metric.values.len));
}

// Calculates the standard deviation of values in a metric
// Calculates 标准 deviation 的 值 在 一个 metric
// Uses the population standard deviation formula: sqrt(sum((x - mean)^2) / n)
// 使用 population 标准 deviation formula: sqrt(sum((x - mean)^2) / n)
pub fn deviation(metric: Metric) f64 {
    const avg = mean(metric);
    var accum: f64 = 0;
    // Sum the squared differences from the mean
    // Sum squared differences 从 mean
    for (metric.values) |value| {
        const delta = value - avg;
        accum += delta * delta;
    }
    // Return the square root of the variance
    // 返回 square root 的 variance
    return std.math.sqrt(accum / @as(f64, @floatFromInt(metric.values.len)));
}

// Classifies a metric as "variable" or "stable" based on its standard deviation
// Classifies 一个 metric 作为 "variable" 或 "stable" 基于 its 标准 deviation
// Metrics with deviation > 3.0 are considered variable, otherwise stable
// Metrics 使用 deviation > 3.0 are considered variable, otherwise stable
pub fn highlight(metric: Metric) []const u8 {
    return if (deviation(metric) > 3.0)
        "variable"
    else
        "stable";
}
