// ! 发现探测器工具函数，演示条件导入和运行时内省。
// ! 此模块展示了如何使用编译时条件来可选加载
// ! 开发工具并使用反射在运行时查询其能力。

const std = @import("std");
const builtin = @import("builtin");

/// 基于构建模式有条件地导入开发钩子。
/// 在调试模式下，导入带有诊断功能的完整dev_probe模块。
/// 在其他模式下（ReleaseSafe、ReleaseFast、ReleaseSmall），提供最小化
/// 存根实现以避免加载不必要的开发工具。
///
/// 此模式实现了零成本抽象，其中开发功能在发布构建中完全省略，
/// 同时保持一致的API。
pub const DevHooks = if (builtin.mode == .Debug)
    @import("tools/dev_probe.zig")
else
    struct {
        /// 非调试构建的最小存根实现。
        /// 返回静态消息，指示开发钩子已禁用。
        pub fn banner() []const u8 {
            return "dev hooks disabled";
        }
    };

/// 入口点，演示模块发现和条件特征检测。
/// 此函数展示：
/// 1. 新的Zig 0.15.2缓冲写入器API用于stdout
/// 2. 编译时条件导入（DevHooks）
/// 3. 使用@hasDecl探测可选函数的运行时内省
pub fn main() !void {
    // 为stdout操作创建栈分配的缓冲区
    var stdout_buffer: [512]u8 = undefined;

    // 使用我们的缓冲区初始化文件写入器。这是Zig 0.15.2
    // I/O改造的一部分，其中写入器现在需要显式缓冲区管理。
    var file_writer = std.fs.File.stdout().writer(&stdout_buffer);

    // 获取通用写入器接口用于格式化输出
    const stdout = &file_writer.interface;

    // 报告当前构建模式（Debug、ReleaseSafe、ReleaseFast、ReleaseSmall）
    try stdout.print("discovery mode: {s}\n", .{@tagName(builtin.mode)});

    // 调用DevHooks中始终可用的banner()函数。
    // 实现根据我们是否处于调试模式而有所不同。
    try stdout.print("dev hooks: {s}\n", .{DevHooks.banner()});

    // 使用@hasDecl检查buildSession()函数是否存在于DevHooks中。
    // 这演示了可选功能的运行时发现，而不需要
    // 所有实现都提供每个函数。
    if (@hasDecl(DevHooks, "buildSession")) {
        // buildSession()仅在完整的dev_probe模块中可用（调试构建）
        try stdout.print("built with zig {s}\n", .{DevHooks.buildSession()});
    } else {
        // 在发布构建中，存根DevHooks不提供buildSession()
        try stdout.print("no buildSession() exported\n", .{});
    }

    // 刷新缓冲输出以确保所有内容写入stdout
    try stdout.flush();
}
