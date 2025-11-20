// ! Utility module demonstrating exported functions and formatted output.
// ! 工具函数 module demonstrating exported 函数 和 格式化 输出.
// ! This module is part of the build system deep dive chapter, showing how to create
// ! 此 module is part 的 构建 system deep dive 章节, showing how 到 创建
// ! library functions that can be exported and used across different build artifacts.
// ! 库 函数 该 can be exported 和 used across different 构建 artifacts.

const std = @import("std");

// / Doubles the input integer value.
// / Doubles 输入 integer 值.
// / This function is exported and can be called from C or other languages.
// / 此 函数 is exported 和 can be called 从 C 或 other languages.
// / Uses the `export` keyword to make it available in the compiled library.
// / 使用 `export` keyword 到 make it available 在 compiled 库.
export fn util_double(x: i32) i32 {
    return x * 2;
}

// / Squares the input integer value.
// / Squares 输入 integer 值.
// / This function is exported and can be called from C or other languages.
// / 此 函数 is exported 和 can be called 从 C 或 other languages.
// / Uses the `export` keyword to make it available in the compiled library.
// / 使用 `export` keyword 到 make it available 在 compiled 库.
export fn util_square(x: i32) i32 {
    return x * x;
}

// / Formats a message with an integer value into the provided buffer.
// / Formats 一个 message 使用 一个 integer 值 into provided 缓冲区.
// / This is a public Zig function (not exported) that demonstrates buffer-based formatting.
// / 此 is 一个 public Zig 函数 (不 exported) 该 演示 缓冲区-based formatting.
/// 
// / Returns a slice of the buffer containing the formatted message, or an error if
// / 返回 一个 切片 的 缓冲区 containing 格式化消息, 或 一个 错误 如果
// / the buffer is too small to hold the formatted output.
// / 缓冲区 is too small 到 hold 格式化 输出.
pub fn formatMessage(buf: []u8, value: i32) ![]const u8 {
    return std.fmt.bufPrint(buf, "Value: {d}", .{value});
}
