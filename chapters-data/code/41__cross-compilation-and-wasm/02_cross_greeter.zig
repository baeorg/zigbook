
// Import the standard library for printing and platform utilities
// 导入标准库 用于 printing 和 platform utilities
const std = @import("std");
// Import builtin to access compile-time target information
// 导入 内置 以访问 编译-time target 信息
const builtin = @import("builtin");

// Entry point that demonstrates cross-compilation by displaying target platform information
// 程序入口点 该 演示 cross-compilation 通过 displaying target platform 信息
pub fn main() void {
    // Print the target platform's CPU architecture, OS, and ABI
    // 打印 target platform's CPU architecture, OS, 和 ABI
    // Uses builtin.target to access compile-time target information
    // 使用 内置.target 以访问 编译-time target 信息
    std.debug.print("hello from {s}-{s}-{s}!\n", .{
        @tagName(builtin.target.cpu.arch),
        @tagName(builtin.target.os.tag),
        @tagName(builtin.target.abi),
    });

    // Retrieve the platform-specific executable file extension (e.g., ".exe" on Windows, "" on Linux)
    // Retrieve platform-specific executable 文件 extension (e.g., ".exe" 在 Windows, "" 在 Linux)
    const suffix = std.Target.Os.Tag.exeFileExt(builtin.target.os.tag, builtin.target.cpu.arch);
    std.debug.print("default executable suffix: {s}\n", .{suffix});
}
