// 此示例演示了 Zig 中的输入验证和错误处理模式，
// 展示了如何创建带有正确边界检查的受控数据处理管道。

const std = @import("std");

// 用于解析和验证操作的自定义错误集
const ParseError = error{
    EmptyInput, // 当输入仅包含空白或为空时返回
    InvalidNumber, // 当输入无法解析为有效数字时返回
    OutOfRange, // 当解析值超出可接受范围时返回
};

// / 将文本输入解析并验证为 u32 限制值。
// / 确保值在 1 到 10,000 之间（含）。
// / 输入中的空白会自动去除。
fn parseLimit(text: []const u8) ParseError!u32 {
    // 移除前导和尾随的空白字符
    const trimmed = std.mem.trim(u8, text, " \t\r\n");
    if (trimmed.len == 0) return error.EmptyInput;

    // 尝试解析为基数为 10 的无符号 32 位整数
    const value = std.fmt.parseInt(u32, trimmed, 10) catch return error.InvalidNumber;

    // 强制边界：拒绝零值和超出最大阈值的值
    if (value == 0 or value > 10_000) return error.OutOfRange;
    return value;
}

// / 对工作队列应用节流限制，确保安全的处理边界。
// / 返回可处理的实际项目数，即请求限制和可用工作长度的最小值。
fn throttle(work: []const u8, limit: u32) ParseError!usize {
    // 前置条件：限制必须为正数（在调试构建中在运行时强制执行）
    std.debug.assert(limit > 0);

    // 防止空工作队列
    if (work.len == 0) return error.EmptyInput;

    // 通过取请求限制和工作大小的最小值来计算安全处理限制
    // 转换是安全的，因为我们取的是最小值
    const safe_limit = @min(limit, @as(u32, @intCast(work.len)));
    return safe_limit;
}

// 测试：验证有效的数字字符串是否正确解析
test "valid limit parses" {
    try std.testing.expectEqual(@as(u32, 750), try parseLimit("750"));
}

// 测试：确保仅包含空白的输入被正确拒绝
test "empty input rejected" {
    try std.testing.expectError(error.EmptyInput, parseLimit("   \n"));
}

// 测试：验证节流尊重解析的限制和工作大小
test "in-flight throttling respects guard" {
    const limit = try parseLimit("32");
    // 工作长度 (4) 小于限制 (32)，因此期望工作长度
    try std.testing.expectEqual(@as(usize, 4), try throttle("hard", limit));
}

// 测试：验证多个输入符合最大阈值要求
// 演示编译时迭代以测试多种场景
test "validate release configurations" {
    const inputs = [_][]const u8{ "8", "9999", "500" };
    // 编译时循环展开每个输入值的测试用例
    inline for (inputs) |value| {
        const parsed = try parseLimit(value);
        // 确保解析值永不超过定义的最大值
        try std.testing.expect(parsed <= 10_000);
    }
}
