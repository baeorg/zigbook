
// / Statistical summary of a numerical dataset.
// / Statistical summary 的 一个 numerical dataset.
// / Contains computed statistics including central tendency, spread, and sample size.
// / Contains computed statistics including central tendency, spread, 和 sample size.
const std = @import("std");

pub const Stats = struct {
    sample_count: usize,
    min: f64,
    max: f64,
    mean: f64,
    variance: f64,

    // / Calculates the range (difference between maximum and minimum values).
    // / Calculates range (difference between maximum 和 minimum 值).
    pub fn range(self: Stats) f64 {
        return self.max - self.min;
    }

    // / Calculates the coefficient of variation (range divided by mean).
    // / Calculates coefficient 的 variation (range divided 通过 mean).
    // / Returns 0 if mean is 0 to avoid division by zero.
    // / 返回 0 如果 mean is 0 到 avoid division 通过 零.
    pub fn relativeSpread(self: Stats) f64 {
        return if (self.mean == 0) 0 else self.range() / self.mean;
    }
};

// / Computes descriptive statistics for a slice of floating-point values.
// / Computes descriptive statistics 用于 一个 切片 的 floating-point 值.
// / Uses Welford's online algorithm for numerically stable variance calculation.
// / 使用 Welford's online algorithm 用于 numerically stable variance calculation.
// / Panics if the input slice is empty.
// / Panics 如果 输入 切片 is 空.
pub fn analyze(values: []const f64) Stats {
    std.debug.assert(values.len > 0);

    var min_value: f64 = values[0];
    var max_value: f64 = values[0];
    var mean_value: f64 = 0.0;
    // M2 is the sum of squares of differences from the current mean (Welford's algorithm)
    // M2 is sum 的 squares 的 differences 从 当前 mean (Welford's algorithm)
    var m2: f64 = 0.0;
    var index: usize = 0;

    while (index < values.len) : (index += 1) {
        const value = values[index];
        // Track minimum and maximum values
        // Track minimum 和 maximum 值
        if (value < min_value) min_value = value;
        if (value > max_value) max_value = value;

        // Welford's online algorithm for mean and variance
        // Welford's online algorithm 用于 mean 和 variance
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
// / 标准 deviation is square root 的 variance.
pub fn sampleStdDev(stats: Stats) f64 {
    return std.math.sqrt(stats.variance);
}

// / Calculates the z-score (standard score) for a given value.
// / Calculates z-score (标准 score) 用于 一个 given 值.
// / Measures how many standard deviations a value is from the mean.
// / Measures how many 标准 deviations 一个 值 is 从 mean.
// / Returns 0 if standard deviation is 0 to avoid division by zero.
// / 返回 0 如果 标准 deviation is 0 到 avoid division 通过 零.
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
