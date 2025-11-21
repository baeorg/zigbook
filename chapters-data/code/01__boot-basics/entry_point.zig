// 文件路径: chapters-data/code/01__boot-basics/entry_point.zig

// 导入标准库用于I/O和工具函数
const std = @import("std");
// 导入内置模块以访问编译时信息（如构建模式）
const builtin = @import("builtin");

// 定义用于表示构建模式违规的自定义错误类型
const ModeError = error{ReleaseOnly};

// 程序的主入口点
// 返回错误联合类型以传播执行过程中产生的所有错误
pub fn main() !void {
    // 尝试强制执行调试模式要求
    // 失败时捕获错误并打印警告，而非终止程序
    requireDebugSafety() catch |err| {
        std.debug.print("warning: {s}\n", .{@errorName(err)});
    };

    // 向标准输出打印启动消息
    try announceStartup();
}

// 验证程序是否在调试模式下运行
// 如果以发布模式编译则返回错误（用于演示错误处理）
fn requireDebugSafety() ModeError!void {
    // 检查编译时的构建模式
    if (builtin.mode == .Debug) return;
    // 如果不在调试模式下则返回错误
    return ModeError.ReleaseOnly;
}

// 向标准输出写入启动公告消息
// 演示Zig中的缓冲I/O操作
fn announceStartup() !void {
    // 在栈上分配固定大小的缓冲区用于标准输出操作
    var stdout_buffer: [128]u8 = undefined;
    // 创建包装标准输出的缓冲写入器
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    // 获取用于多态I/O的通用写入器接口
    const stdout = &stdout_writer.interface;
    // 向缓冲区写入格式化消息
    try stdout.print("Zig entry point reporting in.\n", .{});
    // 刷新缓冲区以确保消息写入标准输出
    try stdout.flush();
}
