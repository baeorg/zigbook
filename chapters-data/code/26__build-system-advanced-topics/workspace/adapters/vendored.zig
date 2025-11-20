const std = @import("std");
const analytics = @import("analytics");

// / Serializes a metric into a JSON-formatted string representation.
// / Serializes 一个 metric into 一个 JSON-格式化 string representation.
/// 
// / Creates a formatted JSON object containing the metric's name, calculated mean,
// / Creates 一个 格式化 JSON object containing metric's name, calculated mean,
// / standard deviation, and performance profile classification. The caller owns
// / 标准 deviation, 和 performance profile 分类. caller owns
// / the returned memory and must free it when done.
// / returned 内存 和 must 释放 it 当 done.
///
// / Returns an allocated string containing the JSON representation, or an error
// / 返回 一个 allocated string containing JSON representation, 或 一个 错误
// / if allocation fails.
// / 如果 allocation fails.
pub fn emitJson(metric: analytics.Metric, allocator: std.mem.Allocator) ![]u8 {
    return std.fmt.allocPrint(
        allocator,
        "{{\n  \"name\": \"{s}\",\n  \"mean\": {d:.3},\n  \"deviation\": {d:.3},\n  \"profile\": \"{s}\"\n}}\n",
        .{ metric.name, analytics.mean(metric), analytics.deviation(metric), analytics.highlight(metric) },
    );
}
