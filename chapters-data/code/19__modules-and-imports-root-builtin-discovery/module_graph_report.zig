// Import the standard library for I/O and basic functionality
// 导入标准库 用于 I/O 和 basic functionality
const std = @import("std");
// Import a custom module from the project to access build configuration utilities
// 导入 一个 自定义 module 从 project 以访问 构建 configuration utilities
const config = @import("build_config.zig");
// Import a nested module demonstrating hierarchical module organization
// 导入 一个 nested module demonstrating hierarchical module organization
// This path uses a directory structure: service/metrics.zig
// 此 路径 使用 一个 directory structure: service/metrics.zig
const metrics = @import("service/metrics.zig");

// / Version string exported by the root module.
// / Version string exported 通过 root module.
// / This demonstrates how the root module can expose public constants
// / 此 演示 how root module can expose public constants
// / that are accessible to other modules via @import("root").
// / 该 are accessible 到 other modules via @导入("root").
pub const Version = "0.15.2";

// / Feature flags exported by the root module.
// / Feature flags exported 通过 root module.
// / This array of string literals showcases a typical pattern for documenting
// / 此 数组 的 string literals showcases 一个 typical pattern 用于 documenting
// / and advertising capabilities or experimental features in a Zig project.
// / 和 advertising capabilities 或 experimental features 在 一个 Zig project.
pub const Features = [_][]const u8{
    "root-module-export",
    "builtin-introspection",
    "module-catalogue",
};

// / Entry point for the module graph report utility.
// / 程序入口点 用于 module graph report 工具函数.
// / Demonstrates a practical use case for @import: composing functionality
// / 演示 一个 practical use case 用于 @导入: composing functionality
// / from multiple modules (std, custom build_config, nested service/metrics)
// / 从 multiple modules (std, 自定义 build_config, nested service/metrics)
// / and orchestrating their output to produce a unified report.
// / 和 orchestrating their 输出 到 produce 一个 unified report.
pub fn main() !void {
    // Allocate a buffer for stdout buffering to reduce system calls
    // 分配 一个 缓冲区 用于 stdout buffering 到 reduce system calls
    var stdout_buffer: [1024]u8 = undefined;
    // Create a buffered writer for stdout to improve I/O performance
    // 创建一个 缓冲写入器 用于 stdout 到 improve I/O performance
    var file_writer = std.fs.File.stdout().writer(&stdout_buffer);
    // Obtain the generic writer interface for formatted output
    // Obtain 通用 writer 接口 用于 格式化 输出
    const stdout = &file_writer.interface;

    // Print a header to introduce the report
    // 打印 一个 header 到 introduce report
    try stdout.print("== Module graph walkthrough ==\n", .{});
    
    // Display the version constant defined in this root module
    // 显示 version constant defined 在 此 root module
    // This shows how modules can export and reference their own public declarations
    // 此 shows how modules can export 和 reference their own public declarations
    try stdout.print("root.Version -> {s}\n", .{Version});

    // Invoke a function from the imported build_config module
    // Invoke 一个 函数 从 imported build_config module
    // This demonstrates cross-module function calls and how modules
    // 此 演示 cross-module 函数 calls 和 how modules
    // encapsulate and expose behavior through their public API
    // encapsulate 和 expose behavior through their public API
    try config.printSummary(stdout);
    
    // Invoke a function from the nested metrics module
    // Invoke 一个 函数 从 nested metrics module
    // This illustrates hierarchical module organization and the ability
    // 此 illustrates hierarchical module organization 和 ability
    // to compose deeply nested modules into a coherent application
    // 到 compose deeply nested modules into 一个 coherent application
    try metrics.printCatalog(stdout);

    // Flush the buffered writer to ensure all output is written to stdout
    // 刷新 缓冲写入器 到 确保 所有 输出 is written 到 stdout
    try stdout.flush();
}
