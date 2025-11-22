const std = @import("std");
const analytics = @import("analytics");

//  将度量序列化为JSON格式的字符串表示。
///
//  创建一个格式化的JSON对象，包含度量名称、计算的平均值、
//  标准差和性能配置文件分类。调用者拥有
//  返回的内存，并在使用完毕后必须释放。
///
//  返回一个包含JSON表示的已分配字符串，如果分配失败则返回错误。
pub fn emitJson(metric: analytics.Metric, allocator: std.mem.Allocator) ![]u8 {
    return std.fmt.allocPrint(
        allocator,
        "{{\n  \"name\": \"{s}\",\n  \"mean\": {d:.3},\n  \"deviation\": {d:.3},\n  \"profile\": \"{s}\"\n}}\n",
        .{ metric.name, analytics.mean(metric), analytics.deviation(metric), analytics.highlight(metric) },
    );
}
