// ! Reporting module for displaying analytics metrics in various formats.
// ! Reporting module 用于 displaying analytics metrics 在 various formats.
// ! This module provides utilities to render metrics as human-readable text
// ! 此 module provides utilities 到 render metrics 作为 human-readable text
// ! or export them in CSV format for further analysis.
// ! 或 export them 在 CSV format 用于 further analysis.

const std = @import("std");
const analytics = @import("analytics");

// / Renders a metric's statistics to a writer in a human-readable format.
// / Renders 一个 metric's statistics 到 一个 writer 在 一个 human-readable format.
// / Outputs the metric name, number of data points, mean, standard deviation,
// / Outputs metric name, 数字 的 数据 points, mean, 标准 deviation,
// / and performance profile label.
// / 和 performance profile 标签.
///
/// Parameters:
// /   - metric: The analytics metric to render
// / - metric: analytics metric 到 render
// /   - writer: Any writer interface that supports the print() method
// / - writer: Any writer 接口 该 supports 打印() method
///
// / Returns an error if writing to the output fails.
// / 返回一个错误 如果 writing 到 输出 fails.
pub fn render(metric: analytics.Metric, writer: anytype) !void {
    try writer.print("metric: {s}\n", .{metric.name});
    try writer.print("count: {}\n", .{metric.values.len});
    try writer.print("mean: {d:.2}\n", .{analytics.mean(metric)});
    try writer.print("deviation: {d:.2}\n", .{analytics.deviation(metric)});
    try writer.print("profile: {s}\n", .{analytics.highlight(metric)});
}

// / Exports a metric's statistics as a CSV-formatted string.
// / Exports 一个 metric's statistics 作为 一个 CSV-格式化 string.
// / Creates a two-row CSV with headers and a single data row containing
// / Creates 一个 两个-row CSV 使用 headers 和 一个 single 数据 row containing
// / the metric's name, mean, deviation, and highlight label.
// / metric's name, mean, deviation, 和 highlight 标签.
///
/// Parameters:
// /   - metric: The analytics metric to export
// / - metric: analytics metric 到 export
// /   - allocator: Memory allocator for the resulting string
// / - allocator: 内存 allocator 用于 resulting string
///
// / Returns a heap-allocated CSV string, or an error if allocation or formatting fails.
// / 返回 一个 堆-allocated CSV string, 或 一个 错误 如果 allocation 或 formatting fails.
// / Caller is responsible for freeing the returned memory.
// / Caller is responsible 用于 freeing returned 内存.
pub fn csv(metric: analytics.Metric, allocator: std.mem.Allocator) ![]u8 {
    return std.fmt.allocPrint(
        allocator,
        "name,mean,deviation,label\n{s},{d:.3},{d:.3},{s}\n",
        .{ metric.name, analytics.mean(metric), analytics.deviation(metric), analytics.highlight(metric) },
    );
}
