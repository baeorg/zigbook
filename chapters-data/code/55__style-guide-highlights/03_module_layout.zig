// ! 突出显示具有集中辅助函数和测试的分层模块布局。
const std = @import("std");

// / 规范化用户提供的重试策略时可能出现的错误。
pub const RetryPolicyError = error{
    ZeroAttempts,
    ExcessiveDelay,
};

// / 封装网络客户端的重试行为，包括合理的默认值。
pub const RetryPolicy = struct {
    max_attempts: u8 = 3,
    delay_ms: u32 = 100,

    /// 指示指数退避是否激活。
    pub fn isBackoffEnabled(self: RetryPolicy) bool {
        return self.delay_ms > 0 and self.max_attempts > 1;
    }
};

//  由配置文件或 CLI 标志提供的部分选项。
pub const PartialRetryOptions = struct {
    max_attempts: ?u8 = null,
    delay_ms: ?u32 = null,
};

//  从可选覆盖构建重试策略，同时保持默认推理集中。
pub fn makeRetryPolicy(options: PartialRetryOptions) RetryPolicy {
    return RetryPolicy{
        .max_attempts = options.max_attempts orelse 3,
        .delay_ms = options.delay_ms orelse 100,
    };
}

fn validate(policy: RetryPolicy) RetryPolicyError!RetryPolicy {
    if (policy.max_attempts == 0) return RetryPolicyError.ZeroAttempts;
    if (policy.delay_ms > 60_000) return RetryPolicyError.ExcessiveDelay;
    return policy;
}

//  生成一个经过验证的策略，强调从原始输入到受限输出的流程。
pub fn finalizeRetryPolicy(options: PartialRetryOptions) RetryPolicyError!RetryPolicy {
    const policy = makeRetryPolicy(options);
    return validate(policy);
}

test "finalize rejects zero attempts" {
    try std.testing.expectError(
        RetryPolicyError.ZeroAttempts,
        finalizeRetryPolicy(.{ .max_attempts = 0 }),
    );
}

test "finalize accepts defaults" {
    const policy = try finalizeRetryPolicy(.{});
    try std.testing.expectEqual(@as(u8, 3), policy.max_attempts);
    try std.testing.expect(policy.isBackoffEnabled());
}
