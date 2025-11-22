// ! Reporting module for displaying analytics metrics in various formats.
// ! 用于以各种格式显示分析指标的报告模块。
// ! This module provides utilities to render metrics as human-readable text
// ! 该模块提供将指标渲染为人类可读文本的工具
// ! or export them in CSV format for further analysis.
// ! 或以 CSV 格式导出它们以进行进一步分析。

const std = @import("std");
const analytics = @import("analytics");

// / Renders a metric's statistics to a writer in a human-readable format.
// / 以人类可读的格式将指标的统计数据渲染到写入器。
// / Outputs the metric name, number of data points, mean, standard deviation,
// / 输出指标名称、数据点数量、平均值、标准差、
// / and performance profile label.
// / 和性能配置文件标签。
///
/// Parameters:
// /   - metric: The analytics metric to render
// /   - metric: 要渲染的分析指标
// /   - writer: Any writer interface that supports the print() method
// /   - writer: 支持 print() 方法的任何写入器接口
///
// / Returns an error if writing to the output fails.
// / 如果写入输出失败，则返回错误。
pub fn render(metric: analytics.Metric, writer: anytype) !void {
    try writer.print("metric: {s}\n", .{metric.name});
    try writer.print("count: {}\n", .{metric.values.len});
    try writer.print("mean: {d:.2}\n", .{analytics.mean(metric)});
    try writer.print("deviation: {d:.2}\n", .{analytics.deviation(metric)});
    try writer.print("profile: {s}\n", .{analytics.highlight(metric)});
}

// / Exports a metric's statistics as a CSV-formatted string.
// / 将指标的统计数据导出为 CSV 格式的字符串。
// / Creates a two-row CSV with headers and a single data row containing
// / 创建一个包含标题的两行 CSV，以及一个包含
// / the metric's name, mean, deviation, and highlight label.
// / 指标名称、平均值、偏差和高亮标签的单行数据。
///
/// Parameters:
// /   - metric: The analytics metric to export
// /   - metric: 要导出的分析指标
// /   - allocator: Memory allocator for the resulting string
// /   - allocator: 用于结果字符串的内存分配器
///
// / Returns a heap-allocated CSV string, or an error if allocation or formatting fails.
// / 返回一个堆分配的 CSV 字符串，如果分配或格式化失败，则返回错误。
// / Caller is responsible for freeing the returned memory.
// / 调用者负责释放返回的内存。
pub fn csv(metric: analytics.Metric, allocator: std.mem.Allocator) ![]u8 {
    return std.fmt.allocPrint(
        allocator,
        "name,mean,deviation,label\n{s},{d:.3},{d:.3},{s}\n",
        .{ metric.name, analytics.mean(metric), analytics.deviation(metric), analytics.highlight(metric) },
    );
}
