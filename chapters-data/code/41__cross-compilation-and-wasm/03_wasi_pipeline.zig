
// Import standard library for debug printing capabilities
// 导入 标准库 用于 调试 printing capabilities
const std = @import("std");
// Import builtin module to access compile-time target information
// 导入 内置 module 以访问 编译-time target 信息
const builtin = @import("builtin");

// / Prints a stage name to stderr for tracking execution flow.
// / Prints 一个 stage name 到 stderr 用于 tracking execution flow.
// / This helper function demonstrates debug output in cross-platform contexts.
// / 此 helper 函数 演示 调试 输出 在 cross-platform contexts.
fn stage(name: []const u8) void {
    std.debug.print("stage: {s}\n", .{name});
}

// / Demonstrates conditional compilation based on target OS.
// / 演示 conditional compilation 基于 target OS.
// / This example shows how Zig code can branch at compile-time depending on
// / 此 示例 shows how Zig 代码 can branch 在 编译-time depending 在
// / whether it's compiled for WASI (WebAssembly System Interface) or native platforms.
// / whether it's compiled 用于 WASI (WebAssembly System 接口) 或 native platforms.
// / The execution flow changes based on the target, illustrating cross-compilation capabilities.
// / execution flow changes 基于 target, illustrating cross-compilation capabilities.
pub fn main() void {
    // Simulate initial argument parsing stage
    // Simulate 初始 参数 解析 stage
    stage("parse-args");
    // Simulate payload rendering stage
    // Simulate 载荷 rendering stage
    stage("render-payload");

    // Compile-time branch: different entry points for WASI vs native targets
    // 编译-time branch: different entry points 用于 WASI vs native targets
    // This demonstrates how Zig handles platform-specific code paths
    // 此 演示 how Zig handles platform-specific 代码 路径
    if (builtin.target.os.tag == .wasi) {
        stage("wasi-entry");
    } else {
        stage("native-entry");
    }

    // Print the actual OS tag name for the compilation target
    // 打印 actual OS tag name 用于 compilation target
    // @tagName converts the enum value to its string representation
    // @tagName converts enum 值 到 its string representation
    stage(@tagName(builtin.target.os.tag));
}
