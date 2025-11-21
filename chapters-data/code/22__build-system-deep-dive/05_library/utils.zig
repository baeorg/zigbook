// ! 实用工具模块，演示导出函数和格式化输出。
// ! 此模块是构建系统深入研究章节的一部分，展示如何创建
// ! 可以导出并在不同构建工件中使用的库函数。

const std = @import("std");

/// 将输入整数值翻倍。
/// 此函数被导出，可以从C或其他语言调用。
/// 使用`export`关键字使其在编译的库中可用。
export fn util_double(x: i32) i32 {
    return x * 2;
}

/// 将输入整数值平方。
/// 此函数被导出，可以从C或其他语言调用。
/// 使用`export`关键字使其在编译的库中可用。
export fn util_square(x: i32) i32 {
    return x * x;
}

/// 使用整数值将消息格式化到提供的缓冲区中。
/// 这是一个公共Zig函数（未导出），演示基于缓冲区的格式化。
///
/// 返回包含格式化消息的缓冲区切片，或如果缓冲区太小而无法容纳格式化输出，则返回错误。
pub fn formatMessage(buf: []u8, value: i32) ![]const u8 {
    return std.fmt.bufPrint(buf, "Value: {d}", .{value});
}
