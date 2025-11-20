
// This module provides log analysis functionality for counting severity levels in log files.
// 此 module provides log analysis functionality 用于 counting severity levels 在 log 文件.
// It demonstrates basic string parsing and struct usage in Zig.
// It 演示 basic string 解析 和 struct usage 在 Zig.
const std = @import("std");

// LogStats holds the count of each log severity level found during analysis.
// LogStats holds count 的 每个 log severity level found during analysis.
// All fields are initialized to zero by default, representing no logs counted yet.
// 所有 fields are initialized 到 零 通过 默认, representing 不 logs counted yet.
pub const LogStats = struct {
    info_count: u32 = 0,
    warn_count: u32 = 0,
    error_count: u32 = 0,
};

/// Analyze log content, counting severity keywords.
// / Returns statistics in a LogStats struct.
// / 返回 statistics 在 一个 LogStats struct.
pub fn analyzeLog(content: []const u8) LogStats {
    // Initialize stats with all counts at zero
    // Initialize stats 使用 所有 counts 在 零
    var stats = LogStats{};
    
    // Create an iterator that splits the content by newline characters
    // 创建 一个 iterator 该 splits content 通过 newline characters
    // This allows us to process the log line by line
    // 此 allows us 到 process log line 通过 line
    var it = std.mem.splitScalar(u8, content, '\n');

    // Process each line in the log content
    // Process 每个 line 在 log content
    while (it.next()) |line| {
        // Count occurrences of severity keywords
        // Count occurrences 的 severity keywords
        // indexOf returns an optional - if found, we increment the corresponding counter
        // indexOf 返回 一个 可选 - 如果 found, we increment 对应的 counter
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

// Test basic log analysis with multiple severity levels
// Test basic log analysis 使用 multiple severity levels
test "analyzeLog basic counting" {
    const input = "INFO startup\nERROR failed\nWARN retry\nINFO success\n";

    const stats = analyzeLog(input);
    
    // Verify each severity level was counted correctly
    // Verify 每个 severity level was counted correctly
    try std.testing.expectEqual(@as(u32, 2), stats.info_count);
    try std.testing.expectEqual(@as(u32, 1), stats.warn_count);
    try std.testing.expectEqual(@as(u32, 1), stats.error_count);
}

// Test that empty input produces zero counts for all severity levels
// Test 该 空 输入 produces 零 counts 用于 所有 severity levels
test "analyzeLog empty input" {
    const input = "";

    const stats = analyzeLog(input);
    
    // All counts should remain at their default zero value
    // 所有 counts should remain 在 their 默认 零 值
    try std.testing.expectEqual(@as(u32, 0), stats.info_count);
    try std.testing.expectEqual(@as(u32, 0), stats.warn_count);
    try std.testing.expectEqual(@as(u32, 0), stats.error_count);
}
