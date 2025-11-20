
// Import standard library for testing utilities
// 导入 标准库 用于 testing utilities
const std = @import("std");
// Import analytics package (libA) for statistical analysis
// 导入 analytics package (libA) 用于 statistical analysis
const analytics = @import("libA");
// Import palette package for theming and styled output
// 导入 palette package 用于 theming 和 styled 输出
const palette = @import("palette");

// / Represents a named collection of numerical data points for analysis
// / Represents 一个 named collection 的 numerical 数据 points 用于 analysis
pub const Dataset = struct {
    name: []const u8,
    values: []const f64,
};

// / Re-export Theme from palette package for consistent theming across reports
// / Re-export Theme 从 palette package 用于 consistent theming across reports
pub const Theme = palette.Theme;

// / Defines threshold values that determine status classification
// / Defines threshold 值 该 确定 状态 分类
// / based on statistical spread of data
// / 基于 statistical spread 的 数据
pub const Thresholds = struct {
    watch: f64,  // Threshold for watch status (lower severity)
    alert: f64,  // Threshold for alert status (higher severity)
};

// / Represents the health status of a dataset based on its statistical spread
// / Represents health 状态 的 一个 dataset 基于 its statistical spread
pub const Status = enum { stable, watch, alert };

// / Determines the status of a dataset by comparing its relative spread
// / Determines 状态 的 一个 dataset 通过 comparing its relative spread
/// against defined thresholds
pub fn status(stats: analytics.Stats, thresholds: Thresholds) Status {
    const spread = stats.relativeSpread();
    // Check against alert threshold first (highest severity)
    // 检查 against alert threshold 首先 (highest severity)
    if (spread >= thresholds.alert) return .alert;
    // Then check watch threshold (medium severity)
    // 那么 检查 watch threshold (medium severity)
    if (spread >= thresholds.watch) return .watch;
    // Default to stable if below all thresholds
    // 默认 到 stable 如果 below 所有 thresholds
    return .stable;
}

// / Returns the default theme from the palette package
// / 返回 默认 theme 从 palette package
pub fn defaultTheme() Theme {
    return palette.defaultTheme();
}

// / Maps a Status value to its corresponding palette Tone for styling
// / Maps 一个 状态 值 到 its 对应的 palette Tone 用于 styling
pub fn tone(status_value: Status) palette.Tone {
    return switch (status_value) {
        .stable => .stable,
        .watch => .watch,
        .alert => .alert,
    };
}

// / Converts a Status value to its string representation
// / Converts 一个 状态 值 到 its string representation
pub fn label(status_value: Status) []const u8 {
    return switch (status_value) {
        .stable => "stable",
        .watch => "watch",
        .alert => "alert",
    };
}

// / Renders a formatted table displaying statistical analysis of multiple datasets
// / Renders 一个 格式化 table displaying statistical analysis 的 multiple datasets
// / with color-coded status indicators based on thresholds
// / 使用 color-coded 状态 indicators 基于 thresholds
pub fn renderTable(
    writer: anytype,
    data_sets: []const Dataset,
    thresholds: Thresholds,
    theme: Theme,
) !void {
    // Print table header with column names
    // 打印 table header 使用 column names
    try writer.print("{s: <12} {s: <10} {s: <10} {s: <10} {s}\n", .{
        "dataset", "status", "mean", "range", "samples",
    });
    // Print separator line
    // 打印 separator line
    try writer.print("{s}\n", .{"-----------------------------------------------"});

    // Process and display each dataset
    // Process 和 显示 每个 dataset
    for (data_sets) |data| {
        // Compute statistics for current dataset
        // Compute statistics 用于 当前 dataset
        const stats = analytics.analyze(data.values);
        const status_value = status(stats, thresholds);

        // Print dataset name
        // 打印 dataset name
        try writer.print("{s: <12} ", .{data.name});
        // Print styled status label with theme-appropriate color
        // 打印 styled 状态 标签 使用 theme-appropriate color
        try palette.writeStyled(theme, tone(status_value), writer, label(status_value));
        // Print statistical values: mean, range, and sample count
        // 打印 statistical 值: mean, range, 和 sample count
        try writer.print(
            " {d: <10.2} {d: <10.2} {d: <10}\n",
            .{ stats.mean, stats.range(), stats.sample_count },
        );
    }
}

// Verifies that status classification correctly responds to different
// Verifies 该 状态 分类 correctly responds 到 different
// levels of data spread relative to defined thresholds
// levels 的 数据 spread relative 到 defined thresholds
test "status thresholds" {
    const thresholds = Thresholds{ .watch = 0.05, .alert = 0.12 };

    // Test with tightly clustered values (low spread) - should be stable
    // Test 使用 tightly clustered 值 (low spread) - should be stable
    const tight = analytics.analyze(&.{ 99.8, 100.1, 100.0 });
    try std.testing.expectEqual(Status.stable, status(tight, thresholds));

    // Test with widely spread values (high spread) - should trigger alert
    // Test 使用 widely spread 值 (high spread) - should trigger alert
    const drift = analytics.analyze(&.{ 100.0, 112.0, 96.0 });
    try std.testing.expectEqual(Status.alert, status(drift, thresholds));
}
