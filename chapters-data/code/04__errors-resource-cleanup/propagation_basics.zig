const std = @import("std");

// 第4章 §1.1 - 此示例命名错误集合并演示`try`如何
// 在不隐藏的情况下将失败向上转发给调用者

const ParseError = error{ InvalidDigit, Overflow };

fn decodeDigit(ch: u8) ParseError!u8 {
    return switch (ch) {
        '0'...'9' => @as(u8, ch - '0'),
        else => error.InvalidDigit,
    };
}

fn accumulate(input: []const u8) ParseError!u8 {
    var total: u8 = 0;
    for (input) |ch| {
        // 每个数字必须成功解析；`try`重新抛出任何
        // `ParseError`以保持外部函数契约的准确性
        const digit = try decodeDigit(ch);
        total = total * 10 + digit;
        if (total > 99) {
            // 传播第二个错误变体以演示调用者看到
            // 完整的错误词汇表
            return error.Overflow;
        }
    }
    return total;
}

pub fn main() !void {
    const samples = [_][]const u8{ "27", "9x", "120" };

    for (samples) |sample| {
        const value = accumulate(sample) catch |err| {
            // 第4章 §1.2将基于此模式构建，但即使在这里我们也记录
            // 错误名称以便失败的输入保持可观察。
            std.debug.print("input \"{s}\" failed with {s}\n", .{ sample, @errorName(err) });
            continue;
        };
        std.debug.print("input \"{s}\" -> {}\n", .{ sample, value });
    }
}
