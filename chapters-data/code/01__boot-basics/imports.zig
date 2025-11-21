// 文件路径: chapters-data/code/01__boot-basics/imports.zig

// 导入标准库用于I/O、内存管理和核心工具
const std = @import("std");
// 导入内置模块以访问构建环境的编译时信息
const builtin = @import("builtin");
// 导入根模块以访问根源文件中的声明
// 此处我们引用app_name，它定义在当前文件中
const root = @import("root");

// 可被其他导入此文件的模块访问的公开常量
pub const app_name = "Boot Basics Tour";

// 程序的主入口点
// 返回错误联合类型以传播执行过程中产生的任何I/O错误
pub fn main() !void {
    // 在栈上分配固定大小的缓冲区用于标准输出操作
    // 此缓冲区批量处理写入操作以减少系统调用
    var stdout_buffer: [256]u8 = undefined;
    // 创建包装标准输出的缓冲写入器
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    // 获取用于多态I/O操作的通用写入器接口
    const stdout = &stdout_writer.interface;

    // 通过引用根模块的声明来打印应用程序名称
    // 演示@import("root")如何允许访问入口文件的公开声明
    try stdout.print("app: {s}\n", .{root.app_name});

    // 打印优化模式（Debug、ReleaseSafe、ReleaseFast或ReleaseSmall）
    // @tagName将枚举值转换为其字符串表示
    try stdout.print("optimize mode: {s}\n", .{@tagName(builtin.mode)});

    // 打印目标三元组，显示CPU架构、操作系统和ABI
    // 每个组件从builtin.target提取并转换为字符串
    try stdout.print(
        "target: {s}-{s}-{s}\n",
        .{
            @tagName(builtin.target.cpu.arch),
            @tagName(builtin.target.os.tag),
            @tagName(builtin.target.abi),
        },
    );

    // 刷新缓冲区以确保所有累积的输出写入标准输出
    try stdout.flush();
}
