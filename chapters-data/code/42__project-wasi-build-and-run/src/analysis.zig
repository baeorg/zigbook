// 此模块提供用于统计日志文件中严重性级别的日志分析功能。
// 它演示了 Zig 中基本的字符串解析和结构体使用。
const std = @import("std");

// LogStats 存储在分析期间发现的每个日志严重性级别的计数。
// 所有字段默认为零，表示尚未计算任何日志。
pub const LogStats = struct {
    info_count: u32 = 0,
    warn_count: u32 = 0,
    error_count: u32 = 0,
};

/// 分析日志内容，统计严重性关键字。
//  在 LogStats 结构体中返回统计信息。
pub fn analyzeLog(content: []const u8) LogStats {
    // 将所有计数初始化为零
    var stats = LogStats{};

    // 创建一个按换行符分割内容的迭代器
    // 这允许我们逐行处理日志
    var it = std.mem.splitScalar(u8, content, '\n');

    // 处理日志内容中的每一行
    while (it.next()) |line| {
        // 统计严重性关键字的出现次数
        // indexOf 返回一个可选值 - 如果找到，我们增加相应的计数器
        if (std.mem.indexOf(u8, line, "INFO")) |_| {
            stats.info_count += 1;
        }
        if (std.mem.indexOf(u8, line, "WARN")) |_| {
            stats.warn_count += 1;
        }
        if (std.mem.indexOf(u8, line, "ERROR")) |_| {
            stats.error_count += 1;
        }
    }

    return stats;
}

// 测试具有多个严重性级别的基本日志分析
test "analyzeLog basic counting" {
    const input = "INFO startup\nERROR failed\nWARN retry\nINFO success\n";

    const stats = analyzeLog(input);

    // 验证每个严重性级别是否正确计数
    try std.testing.expectEqual(@as(u32, 2), stats.info_count);
    try std.testing.expectEqual(@as(u32, 1), stats.warn_count);
    try std.testing.expectEqual(@as(u32, 1), stats.error_count);
}

// 测试空输入是否为所有严重性级别生成零计数
test "analyzeLog empty input" {
    const input = "";

    const stats = analyzeLog(input);

    // 所有计数应保持其默认零值
    try std.testing.expectEqual(@as(u32, 0), stats.info_count);
    try std.testing.expectEqual(@as(u32, 0), stats.warn_count);
    try std.testing.expectEqual(@as(u32, 0), stats.error_count);
}
