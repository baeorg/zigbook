// Analytics library for statistical calculations on metrics
// 用于度量统计计算的分析库
const std = @import("std");

// Represents a named metric with associated numerical values
// 表示具有相关数值的命名度量
pub const Metric = struct {
    name: []const u8,
    values: []const f64,
};

// Calculates the arithmetic mean (average) of all values in a metric
// 计算度量中所有值的算术平均值
// Returns the sum of all values divided by the count
// 返回所有值的总和除以计数
pub fn mean(metric: Metric) f64 {
    var total: f64 = 0;
    for (metric.values) |value| {
        total += value;
    }
    return total / @as(f64, @floatFromInt(metric.values.len));
}

// Calculates the standard deviation of values in a metric
// 计算度量中值的标准差
// Uses the population standard deviation formula: sqrt(sum((x - mean)^2) / n)
// 使用总体标准差公式：sqrt(sum((x - mean)^2) / n)
pub fn deviation(metric: Metric) f64 {
    const avg = mean(metric);
    var accum: f64 = 0;
    // Sum the squared differences from the mean
    // 求和每个值与平均值之差的平方
    for (metric.values) |value| {
        const delta = value - avg;
        accum += delta * delta;
    }
    // Return the square root of the variance
    // 返回方差的平方根
    return std.math.sqrt(accum / @as(f64, @floatFromInt(metric.values.len)));
}

// Classifies a metric as "variable" or "stable" based on its standard deviation
// 根据度量的标准差将其分类为“可变”或“稳定”
// Metrics with deviation > 3.0 are considered variable, otherwise stable
// 偏差 > 3.0 的度量被认为是可变的，否则是稳定的
pub fn highlight(metric: Metric) []const u8 {
    return if (deviation(metric) > 3.0)
        "variable"
    else
        "stable";
}
