
// Import standard library for core functionality
// 导入 标准库 用于 core functionality
const std = @import("std");
// Import analytics module for metric data structures
// 导入 analytics module 用于 metric 数据 structures
const analytics = @import("analytics");
// Import reporting module for metric rendering
// 导入 reporting module 用于 metric rendering
const reporting = @import("reporting");
// Import adapters module for data format conversion
// 导入 adapters module 用于 数据 format conversion
const adapters = @import("adapters");

// / Application entry point demonstrating workspace dependency usage
// / Application 程序入口点 demonstrating workspace dependency usage
// / Shows how to use multiple workspace modules together for metric processing
// / Shows how 到 use multiple workspace modules together 用于 metric processing
pub fn main() !void {
    // Create a fixed-size buffer for stdout operations to avoid dynamic allocation
    // 创建一个 固定大小缓冲区 用于 stdout operations 到 avoid dynamic allocation
    var stdout_buffer: [512]u8 = undefined;
    // Initialize a buffered writer for stdout to improve I/O performance
    // Initialize 一个 缓冲写入器 用于 stdout 到 improve I/O performance
    var writer_state = std.fs.File.stdout().writer(&stdout_buffer);
    const out = &writer_state.interface;

    // Create a sample metric with response time measurements in milliseconds
    // 创建一个 sample metric 使用 response time measurements 在 milliseconds
    const metric = analytics.Metric{
        .name = "response_ms",
        .values = &.{ 12.0, 12.4, 11.9, 12.1, 17.0, 12.3 },
    };

    // Render the metric using the reporting module's formatting
    // Render metric 使用 reporting module's formatting
    try reporting.render(metric, out);

    // Initialize general purpose allocator for JSON serialization
    // Initialize general purpose allocator 用于 JSON serialization
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // Ensure allocator cleanup on function exit
    // 确保 allocator cleanup 在 函数 退出
    defer _ = gpa.deinit();

    // Convert metric to JSON format using the adapters module
    // Convert metric 到 JSON format 使用 adapters module
    const json = try adapters.emitJson(metric, gpa.allocator());
    // Free allocated JSON string when done
    // 释放 allocated JSON string 当 done
    defer gpa.allocator().free(json);

    // Output the JSON representation of the metric
    // 输出 JSON representation 的 metric
    try out.print("json export: {s}\n", .{json});
    // Flush buffered output to ensure all data is written
    // 刷新 缓冲 输出 到 确保 所有 数据 is written
    try out.flush();
}
