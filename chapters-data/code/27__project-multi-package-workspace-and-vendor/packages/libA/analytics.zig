
// / Statistical summary of a numerical dataset.
// / 数值数据集的统计摘要。
// / Contains computed statistics including central tendency, spread, and sample size.
// / 包含计算的统计信息，包括集中趋势、分散度和样本大小。
const std = @import("std");

pub const Stats = struct {
    sample_count: usize,
    min: f64,
    max: f64,
    mean: f64,
    variance: f64,

    // / Calculates the range (difference between maximum and minimum values).
    // / 计算范围（最大值和最小值之间的差值）。
    pub fn range(self: Stats) f64 {
        return self.max - self.min;
    }

    // / Calculates the coefficient of variation (range divided by mean).
    // / 计算变异系数（范围除以平均值）。
    // / Returns 0 if mean is 0 to avoid division by zero.
    // / 如果平均值为0则返回0以避免除零。
    pub fn relativeSpread(self: Stats) f64 {
        return if (self.mean == 0) 0 else self.range() / self.mean;
    }
};

// / Computes descriptive statistics for a slice of floating-point values.
// / 为浮点值切片计算描述性统计。
// / Uses Welford's online algorithm for numerically stable variance calculation.
// / 使用 Welford 在线算法进行数值稳定的方差计算。
// / Panics if the input slice is empty.
// / 如果输入切片为空则 panic。
pub fn analyze(values: []const f64) Stats {
    std.debug.assert(values.len > 0);

    var min_value: f64 = values[0];
    var max_value: f64 = values[0];
    var mean_value: f64 = 0.0;
    // M2 is the sum of squares of differences from the current mean (Welford's algorithm)
    // M2是当前均值的平方差之和（Welford算法）
    var m2: f64 = 0.0;
    var index: usize = 0;

    while (index < values.len) : (index += 1) {
        const value = values[index];
        // Track minimum and maximum values
        // Track minimum 和 maximum 值
        if (value < min_value) min_value = value;
        if (value > max_value) max_value = value;

        // Welford's online algorithm for mean and variance
        // Welford在线算法用于均值和方差
        const count = index + 1;
        const delta = value - mean_value;
        mean_value += delta / @as(f64, @floatFromInt(count));
        const delta2 = value - mean_value;
        m2 += delta * delta2;
    }

    // Calculate sample variance using Bessel's correction (n-1)
    // Calculate sample variance 使用 Bessel's correction (n-1)
    const count_f = @as(f64, @floatFromInt(values.len));
    const variance_value = if (values.len > 1)
        m2 / (count_f - 1.0)
    else
        0.0;

    return Stats{
        .sample_count = values.len,
        .min = min_value,
        .max = max_value,
        .mean = mean_value,
        .variance = variance_value,
    };
}

// / Computes the sample standard deviation from precomputed statistics.
// / Computes sample 标准 deviation 从 precomputed statistics.
// / Standard deviation is the square root of variance.
// / 标准差是方差的平方根。
pub fn sampleStdDev(stats: Stats) f64 {
    return std.math.sqrt(stats.variance);
}

// / Calculates the z-score (standard score) for a given value.
// / Calculates z-score (标准 score) 用于 一个 given 值.
// / Measures how many standard deviations a value is from the mean.
// / Measures how many 标准 deviations 一个 值 is 从 mean.
// / Returns 0 if standard deviation is 0 to avoid division by zero.
// / 如果标准差为0则返回0以避免除零。
pub fn zScore(value: f64, stats: Stats) f64 {
    const dev = sampleStdDev(stats);
    if (dev == 0.0) return 0.0;
    return (value - stats.mean) / dev;
}

test "analyze returns correct statistics" {
    const data = [_]f64{ 12.0, 13.5, 11.8, 12.2, 12.0 };
    const stats = analyze(&data);

    try std.testing.expectEqual(@as(usize, data.len), stats.sample_count);
    try std.testing.expectApproxEqRel(12.3, stats.mean, 1e-6);
    try std.testing.expectApproxEqAbs(1.7, stats.range(), 1e-6);
}
