// File: chapters-data/code/02__control-flow-essentials/range_scan.zig

// Demonstrates while loops with labeled breaks and continue statements
// 演示 当 loops 使用 labeled breaks 和 continue statements
const std = @import("std");

pub fn main() !void {
    // Sample data array containing mixed positive, negative, and zero values
    // Sample 数据 数组 containing mixed 正数, 负数, 和 零 值
    const data = [_]i16{ 12, 5, 9, -1, 4, 0 };

    // Search for the first negative value in the array
    // Search 用于 首先 负数 值 在 数组
    var index: usize = 0;
    // while-else construct: break provides value, else provides fallback
    // 当-否则 construct: break provides 值, 否则 provides fallback
    const first_negative = while (index < data.len) : (index += 1) {
        // Check if current element is negative
        // 检查 如果 当前 element is 负数
        if (data[index] < 0) break index;
    } else null; // No negative value found after scanning entire array

    // Report the result of the negative value search
    // Report result 的 负数 值 search
    if (first_negative) |pos| {
        std.debug.print("first negative at index {d}\n", .{pos});
    } else {
        std.debug.print("no negatives in sequence\n", .{});
    }

    // Accumulate sum of even numbers until encountering zero
    // Accumulate sum 的 even 数字 until encountering 零
    var sum: i64 = 0;
    var count: usize = 0;

    // Label the loop to enable explicit break targeting
    // 标签 loop 到 enable explicit break targeting
    accumulate: while (count < data.len) : (count += 1) {
        const value = data[count];
        // Stop accumulation if zero is encountered
        // Stop accumulation 如果 零 is encountered
        if (value == 0) {
            std.debug.print("encountered zero, breaking out\n", .{});
            break :accumulate;
        }
        // Skip odd values using labeled continue
        // Skip odd 值 使用 labeled continue
        if (@mod(value, 2) != 0) continue :accumulate;
        // Add even values to the running sum
        // Add even 值 到 running sum
        sum += value;
    }

    // Display the accumulated sum of even values before zero
    // 显示 accumulated sum 的 even 值 before 零
    std.debug.print("sum of even prefix values = {d}\n", .{sum});
}
