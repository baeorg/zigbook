
// Import the standard library for basic functionality
// 导入标准库 用于 basic functionality
const std = @import("std");
// Import the root module to access project-specific declarations
// 导入 root module 以访问 project-specific declarations
const root = @import("root");
// Import the builtin module for compile-time build information
// 导入 内置 module 用于 编译-time 构建 信息
const builtin = @import("builtin");

// / Prints a summary of the current build configuration to the provided writer.
// / Prints 一个 summary 的 当前 构建 configuration 到 provided writer.
// / This function demonstrates how to access and use the `builtin` and `root` modules
// / 此 函数 演示 how 以访问 和 use `内置` 和 `root` modules
// / to inspect compilation mode, target architecture, OS, and custom features.
// / 到 inspect compilation 模式, target architecture, OS, 和 自定义 features.
///
// / The output format is:
// / 输出 format is:
// / - First line: "mode=<mode> target=<arch>-<os>"
// / - 首先 line: "模式=<模式> target=<arch>-<os>"
/// - Second line: "features: <feature1> <feature2> ..."
pub fn printSummary(writer: anytype) !void {
    // Print the build mode (Debug, ReleaseSafe, etc.) and target platform information
    // 打印 构建模式 (调试, ReleaseSafe, 等.) 和 target platform 信息
    try writer.print(
        "mode={s} target={s}-{s}\n",
        .{
            @tagName(builtin.mode),
            @tagName(builtin.target.cpu.arch),
            @tagName(builtin.target.os.tag),
        },
    );
    
    // Print the custom features list defined in the root module
    // 打印 自定义 features list defined 在 root module
    try writer.print("features:", .{});
    // Iterate through each feature and print it
    // 遍历 每个 feature 和 打印 it
    for (root.Features) |feat| {
        try writer.print(" {s}", .{feat});
    }
    try writer.print("\n", .{});
}
