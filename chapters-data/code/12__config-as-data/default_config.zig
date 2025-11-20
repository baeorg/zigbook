const std = @import("std");

// / Configuration structure for an application with sensible defaults
// / Configuration structure 用于 一个 application 使用 sensible defaults
const AppConfig = struct {
    // / Theme options for the application UI
    // / Theme options 用于 application UI
    pub const Theme = enum { system, light, dark };

    // Default configuration values are specified inline
    // 默认 configuration 值 are specified inline
    host: []const u8 = "127.0.0.1",
    port: u16 = 8080,
    log_level: std.log.Level = .info,
    instrumentation: bool = false,
    theme: Theme = .system,
    timeouts: Timeouts = .{},

    // / Nested configuration for timeout settings
    // / Nested configuration 用于 timeout settings
    pub const Timeouts = struct {
        connect_ms: u32 = 200,
        read_ms: u32 = 1200,
    };
};

// / Helper function to print configuration values in a human-readable format
// / Helper 函数 到 打印 configuration 值 在 一个 human-readable format
// / writer: any type implementing write() and print() methods
// / writer: any 类型 implementing 写入() 和 打印() methods
// / label: descriptive text to identify this configuration dump
// / 标签: descriptive text 到 identify 此 configuration dump
// / config: the AppConfig instance to display
// / config: AppConfig instance 到 显示
fn dumpConfig(writer: anytype, label: []const u8, config: AppConfig) !void {
    // Print the label header
    // 打印 标签 header
    try writer.print("{s}\n", .{label});
    
    // Print each field with proper formatting
    // 打印 每个 field 使用 proper formatting
    try writer.print("  host = {s}\n", .{config.host});
    try writer.print("  port = {}\n", .{config.port});
    
    // Use @tagName to convert enum values to strings
    // Use @tagName 到 convert enum 值 到 字符串
    try writer.print("  log_level = {s}\n", .{@tagName(config.log_level)});
    try writer.print("  instrumentation = {}\n", .{config.instrumentation});
    try writer.print("  theme = {s}\n", .{@tagName(config.theme)});
    
    // Print nested struct in single line
    // 打印 nested struct 在 single line
    try writer.print(
        "  timeouts = .{{ connect_ms = {}, read_ms = {} }}\n",
        .{ config.timeouts.connect_ms, config.timeouts.read_ms },
    );
}

pub fn main() !void {
    // Allocate a fixed buffer for stdout operations
    // 分配 一个 fixed 缓冲区 用于 stdout operations
    var stdout_buffer: [2048]u8 = undefined;
    
    // Create a buffered writer for stdout to reduce syscalls
    // 创建一个 缓冲写入器 用于 stdout 到 reduce syscalls
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    // Create a config using all default values (empty initializer)
    // 创建一个 config 使用 所有 默认 值 (空 initializer)
    const defaults = AppConfig{};
    try dumpConfig(stdout, "defaults ->", defaults);

    // Create a config with several overridden values
    // 创建一个 config 使用 several overridden 值
    // Fields not specified here retain their defaults from the struct definition
    // Fields 不 specified here retain their defaults 从 struct definition
    const tuned = AppConfig{
        .host = "0.0.0.0",        // Bind to all interfaces
        .port = 9090,              // Custom port
        .log_level = .debug,       // More verbose logging
        .instrumentation = true,   // Enable performance monitoring
        .theme = .dark,            // Dark theme instead of system default
        .timeouts = .{             // Override nested timeout values
            .connect_ms = 75,      // Faster connection timeout
            .read_ms = 1500,       // Longer read timeout
        },
    };

    // Add blank line between the two config dumps
    // Add blank line between 两个 config dumps
    try stdout.writeByte('\n');
    
    // Display the customized configuration
    // 显示 customized configuration
    try dumpConfig(stdout, "overrides ->", tuned);
    
    // Flush the buffer to ensure all output is written to stdout
    // 刷新 缓冲区 到 确保 所有 输出 is written 到 stdout
    try stdout.flush();
}
