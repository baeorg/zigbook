// 导入标准库以获取I/O和基本功能
const std = @import("std");
// 导入内置模块以访问编译时构建信息
const builtin = @import("builtin");

// 在编译时计算关于当前优化模式的人类可读提示。
// 此块在编译期间评估一次并将结果嵌入为常量字符串。
const optimize_hint = blk: {
    break :blk switch (builtin.mode) {
        .Debug => "调试符号和运行时安全检查已启用",
        .ReleaseSafe => "运行时检查已启用，优化以确保安全",
        .ReleaseFast => "优化优先考虑速度",
        .ReleaseSmall => "优化优先考虑大小",
    };
};

/// 内置探测器工具函数的入口点。
/// 演示如何查询和显示来自`builtin`模块的编译时构建配置，
/// 包括Zig版本、优化模式、目标平台详细信息和链接选项。
pub fn main() !void {
    // 为stdout分配缓冲区以减少系统调用
    var stdout_buffer: [1024]u8 = undefined;
    // 为stdout创建缓冲写入器以提高I/O性能
    var file_writer = std.fs.File.stdout().writer(&stdout_buffer);
    // 获取通用写入器接口用于格式化输出
    const out = &file_writer.interface;

    // 打印嵌入在编译时的Zig编译器版本字符串
    try out.print("zig version (compiler): {s}\n", .{builtin.zig_version_string});

    // 打印优化模式及其对应的描述
    try out.print("optimize mode: {s} — {s}\n", .{ @tagName(builtin.mode), optimize_hint });

    // 打印目标三元组：架构、操作系统和ABI
    // 这些值反映编译二进制文件的平台
    try out.print(
        "target triple: {s}-{s}-{s}\n",
        .{
            @tagName(builtin.target.cpu.arch),
            @tagName(builtin.target.os.tag),
            @tagName(builtin.target.abi),
        },
    );

    // 指示二进制是否以单线程模式构建
    try out.print("single-threaded build: {}\n", .{builtin.single_threaded});

    // 指示是否链接标准C库（libc）
    try out.print("linking libc: {}\n", .{builtin.link_libc});

    // 编译时块，用于在运行测试时有条件地导入测试辅助函数。
    // 这演示了使用`builtin.is_test`启用仅测试代码路径。
    comptime {
        if (builtin.is_test) {
            // 根模块可以使用此钩子启用仅测试辅助函数。
            _ = @import("test_helpers.zig");
        }
    }

    // 刷新缓冲写入器以确保所有输出写入stdout
    try out.flush();
}
