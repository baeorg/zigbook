// Main application entry point that demonstrates multi-package workspace usage
// 主应用程序入口点，演示多包工作区的使用
// by generating a performance report table with multiple datasets.
// 通过生成包含多个数据集的性能报告表。

// Import the standard library for I/O operations
// 导入标准库以进行I/O操作
const std = @import("std");
// Import the reporting library (libB) from the workspace
// 从工作区导入报告库 (libB)
const report = @import("libB");

//  Application entry point that creates and renders a performance monitoring report.
//  创建和渲染性能监控报告的应用程序入口点。
//  Demonstrates integration with the libB package for generating formatted tables
//  演示与 libB 包集成，以生成格式化表格
//  with threshold-based highlighting.
//  并带有基于阈值的突出显示。
pub fn main() !void {
    // Allocate a fixed buffer for stdout to avoid dynamic allocation
    // 为标准输出分配固定缓冲区以避免动态分配
    var stdout_buffer: [1024]u8 = undefined;
    // Create a buffered writer for efficient stdout operations
    // 创建一个缓冲写入器以实现高效的标准输出操作
    var writer_state = std.fs.File.stdout().writer(&stdout_buffer);
    // Get the generic writer interface for use with the report library
    // 获取通用写入器接口以与报告库一起使用
    const out = &writer_state.interface;

    // Define sample performance datasets for different system components
    // 定义用于不同系统组件的示例性能数据集
    // Each dataset contains a component name and an array of performance values
    // 每个数据集包含一个组件名称和一组性能值
    const datasets = [_]report.Dataset{
        .{ .name = "frontend", .values = &.{ 112.0, 109.5, 113.4, 112.2, 111.9 } },
        .{ .name = "checkout", .values = &.{ 98.0, 101.0, 104.4, 99.1, 100.5 } },
        .{ .name = "analytics", .values = &.{ 67.0, 89.4, 70.2, 91.0, 69.5 } },
    };

    // Configure monitoring thresholds: 8% variance triggers watch, 20% triggers alert
    // 配置监控阈值：8%方差触发警告，20%触发警报
    const thresholds = report.Thresholds{ .watch = 0.08, .alert = 0.2 };
    // Use the default color theme provided by the report library
    // 使用报告库提供的默认颜色主题
    const theme = report.defaultTheme();

    // Render the formatted report table to the buffered writer
    // 将格式化的报告表渲染到缓冲写入器
    try report.renderTable(out, &datasets, thresholds, theme);
    // Flush the buffer to ensure all output is written to stdout
    // 刷新缓冲区以确保所有输出写入标准输出
    try out.flush();
}
