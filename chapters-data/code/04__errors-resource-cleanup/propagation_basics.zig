const std = @import("std");

// Chapter 4 §1.1 – this sample names an error set and shows how `try` forwards
// 第4章§1.1 - 此示例命名错误集合并演示`try`如何
// failures up to the caller without hiding them along the way.
// 在不隐藏的情况下将错误向上转发给调用者

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
        // Each digit must parse successfully; `try` re-raises any
        // 每个数字必须成功解析；`try`重新抛出任何
        // `ParseError` so the outer function's contract stays accurate.
        // `ParseError`以保持外部函数契约的准确性
        const digit = try decodeDigit(ch);
        total = total * 10 + digit;
        if (total > 99) {
            // Propagate a second error variant to demonstrate that callers see
            // 传播第二个错误变体以演示调用者看到
            // a complete vocabulary of what can go wrong.
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
            // Chapter 4 §1.2 will build on this pattern, but even here we log
            // 章节 4 §1.2 will 构建 在 此 pattern, but even here we log
            // the error name so failed inputs remain observable.
            // 错误 name so 失败 inputs remain observable.
            std.debug.print("input \"{s}\" failed with {s}\n", .{ sample, @errorName(err) });
            continue;
        };
        std.debug.print("input \"{s}\" -> {}\n", .{ sample, value });
    }
}
