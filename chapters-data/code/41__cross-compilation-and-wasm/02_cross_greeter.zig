// 导入标准库以获取打印和平台工具
const std = @import("std");
// 导入内置模块以访问编译时目标信息
const builtin = @import("builtin");

// 演示通过显示目标平台信息进行交叉编译的入口点
pub fn main() void {
    // 打印目标平台的 CPU 架构、操作系统和 ABI
    // 使用 builtin.target 访问编译时目标信息
    std.debug.print("hello from {s}-{s}-{s}!\n", .{
        @tagName(builtin.target.cpu.arch),
        @tagName(builtin.target.os.tag),
        @tagName(builtin.target.abi),
    });

    // 检索特定于平台的 EXE 文件扩展名（例如，Windows 上的“.exe”，Linux 上的“”）
    const suffix = std.Target.Os.Tag.exeFileExt(builtin.target.os.tag, builtin.target.cpu.arch);
    std.debug.print("default executable suffix: {s}\n", .{suffix});
}
