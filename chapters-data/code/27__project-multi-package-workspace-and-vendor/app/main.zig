// Main application entry point that demonstrates multi-package workspace usage
// 主 application 程序入口点 该 演示 multi-package workspace usage
// by generating a performance report table with multiple datasets.
// 通过 generating 一个 performance report table 使用 multiple datasets.

// Import the standard library for I/O operations
// 导入标准库 用于 I/O operations
const std = @import("std");
// Import the reporting library (libB) from the workspace
// 导入 reporting 库 (libB) 从 workspace
const report = @import("libB");

// / Application entry point that creates and renders a performance monitoring report.
// / Application 程序入口点 该 creates 和 renders 一个 performance monitoring report.
// / Demonstrates integration with the libB package for generating formatted tables
// / 演示 integration 使用 libB package 用于 generating 格式化 tables
// / with threshold-based highlighting.
// / 使用 threshold-based highlighting.
pub fn main() !void {
    // Allocate a fixed buffer for stdout to avoid dynamic allocation
    // 分配 一个 fixed 缓冲区 用于 stdout 到 avoid dynamic allocation
    var stdout_buffer: [1024]u8 = undefined;
    // Create a buffered writer for efficient stdout operations
    // 创建一个 缓冲写入器 用于 efficient stdout operations
    var writer_state = std.fs.File.stdout().writer(&stdout_buffer);
    // Get the generic writer interface for use with the report library
    // 获取 通用 writer 接口 用于 use 使用 report 库
    const out = &writer_state.interface;

    // Define sample performance datasets for different system components
    // 定义 sample performance datasets 用于 different system components
    // Each dataset contains a component name and an array of performance values
    // 每个 dataset contains 一个 component name 和 一个 数组 的 performance 值
    const datasets = [_]report.Dataset{
        .{ .name = "frontend", .values = &.{ 112.0, 109.5, 113.4, 112.2, 111.9 } },
        .{ .name = "checkout", .values = &.{ 98.0, 101.0, 104.4, 99.1, 100.5 } },
        .{ .name = "analytics", .values = &.{ 67.0, 89.4, 70.2, 91.0, 69.5 } },
    };

    // Configure monitoring thresholds: 8% variance triggers watch, 20% triggers alert
    const thresholds = report.Thresholds{ .watch = 0.08, .alert = 0.2 };
    // Use the default color theme provided by the report library
    // Use 默认 color theme provided 通过 report 库
    const theme = report.defaultTheme();

    // Render the formatted report table to the buffered writer
    // Render 格式化 report table 到 缓冲写入器
    try report.renderTable(out, &datasets, thresholds, theme);
    // Flush the buffer to ensure all output is written to stdout
    // 刷新 缓冲区 到 确保 所有 输出 is written 到 stdout
    try out.flush();
}
