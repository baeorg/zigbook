
// Import the standard library for testing utilities
// 导入标准库 用于 testing utilities
const std = @import("std");

// / String utilities for text processing
// / String utilities 用于 text processing
pub const StringUtils = struct {
    // / Count occurrences of a character in a string
    // / Count occurrences 的 一个 character 在 一个 string
    // / Returns the total number of times the specified character appears
    // / 返回 total 数字 的 times specified character appears
    pub fn countChar(text: []const u8, char: u8) usize {
        var count: usize = 0;
        // Iterate through each character in the text
        // 遍历 每个 character 在 text
        for (text) |c| {
            // Increment counter when matching character is found
            // Increment counter 当 matching character is found
            if (c == char) count += 1;
        }
        return count;
    }

    // / Check if string contains only ASCII characters
    // / 检查 如果 string contains only ASCII characters
    // / ASCII characters have values from 0-127
    // / ASCII characters have 值 从 0-127
    pub fn isAscii(text: []const u8) bool {
        for (text) |c| {
            // Any character with value > 127 is non-ASCII
            // Any character 使用 值 > 127 is non-ASCII
            if (c > 127) return false;
        }
        return true;
    }

    // / Reverse a string in place
    // / Reverse 一个 string 在 place
    // / Modifies the input buffer directly using two-pointer technique
    // / Modifies 输入 缓冲区 directly 使用 两个-pointer technique
    pub fn reverse(text: []u8) void {
        // Early return for empty strings
        // Early 返回 用于 空 字符串
        if (text.len == 0) return;
        
        var left: usize = 0;
        var right: usize = text.len - 1;
        
        // Swap characters from both ends moving towards the center
        // Swap characters 从 both ends moving towards center
        while (left < right) {
            const temp = text[left];
            text[left] = text[right];
            text[right] = temp;
            left += 1;
            right -= 1;
        }
    }
};

// Test suite verifying countChar functionality with various inputs
// Test suite verifying countChar functionality 使用 various inputs
test "countChar counts occurrences" {
    const text = "hello world";
    // Verify counting of 'l' character (appears 3 times)
    // Verify counting 的 'l' character (appears 3 times)
    try std.testing.expectEqual(@as(usize, 3), StringUtils.countChar(text, 'l'));
    // Verify counting of 'o' character (appears 2 times)
    // Verify counting 的 'o' character (appears 2 times)
    try std.testing.expectEqual(@as(usize, 2), StringUtils.countChar(text, 'o'));
    // Verify counting returns 0 for non-existent character
    // Verify counting 返回 0 用于 non-existent character
    try std.testing.expectEqual(@as(usize, 0), StringUtils.countChar(text, 'x'));
}

// Test suite verifying ASCII detection for different character sets
// Test suite verifying ASCII detection 用于 different character sets
test "isAscii detects ASCII strings" {
    // Standard ASCII letters should return true
    // 标准 ASCII letters should 返回 true
    try std.testing.expect(StringUtils.isAscii("hello"));
    // ASCII digits should return true
    // ASCII digits should 返回 true
    try std.testing.expect(StringUtils.isAscii("123"));
    // String with non-ASCII character (é = 233) should return false
    // String 使用 non-ASCII character (é = 233) should 返回 false
    try std.testing.expect(!StringUtils.isAscii("héllo"));
}

// Test suite verifying in-place string reversal
// Test suite verifying 在-place string reversal
test "reverse reverses string" {
    // Create a mutable buffer to test in-place reversal
    // 创建一个 mutable 缓冲区 到 test 在-place reversal
    var buffer = [_]u8{ 'h', 'e', 'l', 'l', 'o' };
    StringUtils.reverse(&buffer);
    // Verify the buffer contents are reversed
    // Verify 缓冲区 contents are reversed
    try std.testing.expectEqualSlices(u8, "olleh", &buffer);
}
