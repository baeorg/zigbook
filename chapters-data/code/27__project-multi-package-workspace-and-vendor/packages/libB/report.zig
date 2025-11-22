// Import standard library for testing utilities
// 导入标准库以获取测试工具
const std = @import("std");
// Import analytics package (libA) for statistical analysis
// 导入 analytics 包 (libA) 以进行统计分析
const analytics = @import("libA");
// Import palette package for theming and styled output
// 导入 palette 包以用于主题和样式输出
const palette = @import("palette");

// / Represents a named collection of numerical data points for analysis
// / 表示用于分析的数值数据点的命名集合
pub const Dataset = struct {
    name: []const u8,
    values: []const f64,
};

// / Re-export Theme from palette package for consistent theming across reports
// / 从 palette 包重新导出 Theme，以便在报告中保持一致的主题
pub const Theme = palette.Theme;

// / Defines threshold values that determine status classification
// / 定义确定状态分类的阈值
// / based on statistical spread of data
// / 基于数据的统计分布
pub const Thresholds = struct {
    watch: f64, // Threshold for watch status (lower severity)
    // 观察状态的阈值（较低严重性）
    alert: f64, // Threshold for alert status (higher severity)
    // 警报状态的阈值（较高严重性）
};

// / Represents the health status of a dataset based on its statistical spread
// / 表示基于数据集统计分布的健康状态
pub const Status = enum { stable, watch, alert };

// / Determines the status of a dataset by comparing its relative spread
// / 通过比较数据集的相对分布来确定其状态
/// against defined thresholds
/// 对比定义的阈值
pub fn status(stats: analytics.Stats, thresholds: Thresholds) Status {
    const spread = stats.relativeSpread();
    // Check against alert threshold first (highest severity)
    // 首先检查警报阈值（最高严重性）
    if (spread >= thresholds.alert) return .alert;
    // Then check watch threshold (medium severity)
    // 然后检查观察阈值（中等严重性）
    if (spread >= thresholds.watch) return .watch;
    // Default to stable if below all thresholds
    // 如果低于所有阈值，则默认为稳定
    return .stable;
}

// / Returns the default theme from the palette package
// / 从 palette 包返回默认主题
pub fn defaultTheme() Theme {
    return palette.defaultTheme();
}

// / Maps a Status value to its corresponding palette Tone for styling
// / 将状态值映射到其对应的 palette 调色板色调以进行样式设置
pub fn tone(status_value: Status) palette.Tone {
    return switch (status_value) {
        .stable => .stable,
        .watch => .watch,
        .alert => .alert,
    };
}

//  Converts a Status value to its string representation
//  将状态值转换为其字符串表示形式
pub fn label(status_value: Status) []const u8 {
    return switch (status_value) {
        .stable => "stable",
        .watch => "watch",
        .alert => "alert",
    };
}

//  Renders a formatted table displaying statistical analysis of multiple datasets
//  渲染一个格式化表格，显示多个数据集的统计分析
//  with color-coded status indicators based on thresholds
//  并带有基于阈值的颜色编码状态指示器
pub fn renderTable(
    writer: anytype,
    data_sets: []const Dataset,
    thresholds: Thresholds,
    theme: Theme,
) !void {
    // Print table header with column names
    // 打印包含列名的表格头
    try writer.print("{s: <12} {s: <10} {s: <10} {s: <10} {s}\n", .{
        "dataset", "status", "mean", "range", "samples",
    });
    // Print separator line
    // 打印分隔线
    try writer.print("{s}\n", .{"-----------------------------------------------"});

    // Process and display each dataset
    // 处理并显示每个数据集
    for (data_sets) |data| {
        // Compute statistics for current dataset
        // 计算当前数据集的统计数据
        const stats = analytics.analyze(data.values);
        const status_value = status(stats, thresholds);

        // Print dataset name
        // 打印数据集名称
        try writer.print("{s: <12} ", .{data.name});
        // Print styled status label with theme-appropriate color
        // 打印带有主题相应颜色的样式化状态标签
        try palette.writeStyled(theme, tone(status_value), writer, label(status_value));
        // Print statistical values: mean, range, and sample count
        // 打印统计值：平均值、范围和样本计数
        try writer.print(
            " {d: <10.2} {d: <10.2} {d: <10}\n",
            .{ stats.mean, stats.range(), stats.sample_count },
        );
    }
}

// Verifies that status classification correctly responds to different
// 验证状态分类正确响应不同
// levels of data spread relative to defined thresholds
// 相对于定义阈值的数据分布级别
test "status thresholds" {
    const thresholds = Thresholds{ .watch = 0.05, .alert = 0.12 };

    // Test with tightly clustered values (low spread) - should be stable
    // 测试紧密聚集的值（低分布）- 应为稳定
    const tight = analytics.analyze(&.{ 99.8, 100.1, 100.0 });
    try std.testing.expectEqual(Status.stable, status(tight, thresholds));

    // Test with widely spread values (high spread) - should trigger alert
    // 测试广泛分布的值（高分布）- 应触发警报
    const drift = analytics.analyze(&.{ 100.0, 112.0, 96.0 });
    try std.testing.expectEqual(Status.alert, status(drift, thresholds));
}
