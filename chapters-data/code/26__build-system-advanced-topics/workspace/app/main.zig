// Import standard library for core functionality
// 导入标准库以获取核心功能
const std = @import("std");
// Import analytics module for metric data structures
// 导入 analytics 模块以获取度量数据结构
const analytics = @import("analytics");
// Import reporting module for metric rendering
// 导入 reporting 模块以进行度量渲染
const reporting = @import("reporting");
// Import adapters module for data format conversion
// 导入 adapters 模块以进行数据格式转换
const adapters = @import("adapters");

//  Application entry point demonstrating workspace dependency usage
//  演示工作区依赖项使用的应用程序入口点
//  Shows how to use multiple workspace modules together for metric processing
//  展示如何将多个工作区模块结合用于度量处理
pub fn main() !void {
    // Create a fixed-size buffer for stdout operations to avoid dynamic allocation
    // 为标准输出操作创建一个固定大小的缓冲区以避免动态分配
    var stdout_buffer: [512]u8 = undefined;
    // Initialize a buffered writer for stdout to improve I/O performance
    // 初始化一个缓冲写入器以提高标准输出I/O性能
    var writer_state = std.fs.File.stdout().writer(&stdout_buffer);
    const out = &writer_state.interface;

    // Create a sample metric with response time measurements in milliseconds
    // 创建一个包含响应时间测量（毫秒）的示例度量
    const metric = analytics.Metric{
        .name = "response_ms",
        .values = &.{ 12.0, 12.4, 11.9, 12.1, 17.0, 12.3 },
    };

    // Render the metric using the reporting module's formatting
    // 使用 reporting 模块的格式化功能渲染度量
    try reporting.render(metric, out);

    // Initialize general purpose allocator for JSON serialization
    // 初始化用于JSON序列化的通用分配器
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // Ensure allocator cleanup on function exit
    // 确保函数退出时清理分配器
    defer _ = gpa.deinit();

    // Convert metric to JSON format using the adapters module
    // 使用 adapters 模块将度量转换为JSON格式
    const json = try adapters.emitJson(metric, gpa.allocator());
    // Free allocated JSON string when done
    // 完成后释放已分配的JSON字符串
    defer gpa.allocator().free(json);

    // Output the JSON representation of the metric
    // 输出度量的JSON表示
    try out.print("json export: {s}\n", .{json});
    // Flush buffered output to ensure all data is written
    // 刷新缓冲输出以确保所有数据写入
    try out.flush();
}
