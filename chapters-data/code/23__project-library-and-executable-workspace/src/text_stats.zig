const std = @import("std");

// / Text statistics and analysis structure
// / Text statistics 和 analysis structure
// / Provides functionality to analyze text content and compute various metrics
// / Provides functionality 到 analyze text content 和 compute various metrics
// / such as word count, line count, and character count.
// / 如 word count, line count, 和 character count.
pub const TextStats = struct {
    // / Total number of words found in the analyzed text
    // / Total 数字 的 words found 在 analyzed text
    word_count: usize,
    // / Total number of lines in the analyzed text
    // / Total 数字 的 lines 在 analyzed text
    line_count: usize,
    // / Total number of characters in the analyzed text
    // / Total 数字 的 characters 在 analyzed text
    char_count: usize,


    // / Analyze text and compute statistics
    // / Analyze text 和 compute statistics
    // / Iterates through the input text to count words, lines, and characters.
    // / Iterates through 输入 text 到 count words, lines, 和 characters.
    // / Words are defined as sequences of non-whitespace characters separated by whitespace.
    // / Words are defined 作为 sequences 的 non-whitespace characters separated 通过 whitespace.
    // / Lines are counted based on newline characters, with special handling for text
    // / Lines are counted 基于 newline characters, 使用 special handling 用于 text
    // / that doesn't end with a newline.
    // / 该 doesn't end 使用 一个 newline.
    pub fn analyze(text: []const u8) TextStats {
        var stats = TextStats{
            .word_count = 0,
            .line_count = 0,
            .char_count = text.len,
        };

        // Track whether we're currently inside a word to avoid counting multiple
        // Track whether we're currently inside 一个 word 到 avoid counting multiple
        // consecutive whitespace characters as separate word boundaries
        // consecutive whitespace characters 作为 separate word boundaries
        var in_word = false;
        for (text) |c| {
            if (c == '\n') {
                stats.line_count += 1;
                in_word = false;
            } else if (std.ascii.isWhitespace(c)) {
                // Whitespace marks the end of a word
                // Whitespace marks end 的 一个 word
                in_word = false;
            } else if (!in_word) {
                // Transition from whitespace to non-whitespace marks a new word
                // Transition 从 whitespace 到 non-whitespace marks 一个 新 word
                stats.word_count += 1;
                in_word = true;
            }
        }

        // Count last line if text doesn't end with newline
        // Count 最后一个 line 如果 text doesn't end 使用 newline
        if (text.len > 0 and text[text.len - 1] != '\n') {
            stats.line_count += 1;
        }

        return stats;
    }

    // Format and write statistics to the provided writer
    // Format 和 写入 statistics 到 provided writer
    // Outputs the statistics in a human-readable format: "Lines: X, Words: Y, Chars: Z"
    // Outputs statistics 在 一个 human-readable format: "Lines: X, Words: Y, Chars: Z"
    pub fn format(self: TextStats, writer: *std.Io.Writer) std.Io.Writer.Error!void {
        try writer.print("Lines: {d}, Words: {d}, Chars: {d}", .{
            self.line_count,
            self.word_count,
            self.char_count,
        });
    }
};

// Verify that TextStats correctly analyzes multi-line text with multiple words
// Verify 该 TextStats correctly analyzes multi-line text 使用 multiple words
test "TextStats analyzes simple text" {
    const text = "hello world\nfoo bar";
    const stats = TextStats.analyze(text);
    try std.testing.expectEqual(@as(usize, 2), stats.line_count);
    try std.testing.expectEqual(@as(usize, 4), stats.word_count);
    try std.testing.expectEqual(@as(usize, 19), stats.char_count);
}

// Verify that TextStats correctly handles edge case of empty input
// Verify 该 TextStats correctly handles edge case 的 空 输入
test "TextStats handles empty text" {
    const text = "";
    const stats = TextStats.analyze(text);
    try std.testing.expectEqual(@as(usize, 0), stats.line_count);
    try std.testing.expectEqual(@as(usize, 0), stats.word_count);
    try std.testing.expectEqual(@as(usize, 0), stats.char_count);
}
