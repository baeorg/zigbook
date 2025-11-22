// ! 保持数值解析器的错误词汇紧凑，以便调用者能精确响应。
const std = @import("std");

// / 枚举解析器可以向其调用者报告的故障模式。
pub const ParseCountError = error{
    EmptyInput,
    InvalidDigit,
    Overflow,
};

// / 解析十进制计数器，同时保留描述性错误信息。
pub fn parseCount(input: []const u8) ParseCountError!u32 {
    if (input.len == 0) return ParseCountError.EmptyInput;

    var acc: u64 = 0;
    for (input) |char| {
        if (char < '0' or char > '9') return ParseCountError.InvalidDigit;
        const digit: u64 = @intCast(char - '0');
        acc = acc * 10 + digit;
        if (acc > std.math.maxInt(u32)) return ParseCountError.Overflow;
    }

    return @intCast(acc);
}

test "parseCount reports invalid digits precisely" {
    try std.testing.expectEqual(@as(u32, 42), try parseCount("42"));
    try std.testing.expectError(ParseCountError.InvalidDigit, parseCount("4a"));
    try std.testing.expectError(ParseCountError.EmptyInput, parseCount(""));
    try std.testing.expectError(ParseCountError.Overflow, parseCount("42949672960"));
}
