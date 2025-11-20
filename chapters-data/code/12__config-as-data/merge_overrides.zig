const std = @import("std");

// / Configuration structure for an application with sensible defaults
// / Configuration structure 用于 一个 application 使用 sensible defaults
const AppConfig = struct {
    // / Theme options for the application UI
    // / Theme options 用于 application UI
    pub const Theme = enum { system, light, dark };

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

// / Structure representing optional configuration overrides
// / Structure representing 可选 configuration overrides
// / Each field is optional (nullable) to indicate whether it should override the base config
// / 每个 field is 可选 (nullable) 到 indicate whether it should override base config
const Overrides = struct {
    host: ?[]const u8 = null,
    port: ?u16 = null,
    log_level: ?std.log.Level = null,
    instrumentation: ?bool = null,
    theme: ?AppConfig.Theme = null,
    timeouts: ?AppConfig.Timeouts = null,
};

// / Merges a single layer of overrides into a base configuration
// / Merges 一个 single layer 的 overrides into 一个 base configuration
// / base: the starting configuration to modify
// / base: starting configuration 到 modify
// / overrides: optional values that should replace corresponding base fields
// / overrides: 可选 值 该 should replace 对应的 base fields
// / Returns: a new AppConfig with overrides applied
// / 返回: 一个 新 AppConfig 使用 overrides applied
fn merge(base: AppConfig, overrides: Overrides) AppConfig {
    // Start with a copy of the base configuration
    // Start 使用 一个 复制 的 base configuration
    var result = base;
    
    // Iterate over all fields in the Overrides struct at compile time
    // 迭代 over 所有 fields 在 Overrides struct 在 编译时
    inline for (std.meta.fields(Overrides)) |field| {
        // Check if this override field has a non-null value
        // 检查 如果 此 override field has 一个 non-空 值
        if (@field(overrides, field.name)) |value| {
            // If present, replace the corresponding field in result
            // 如果 存在, replace 对应的 field 在 result
            @field(result, field.name) = value;
        }
    }
    
    return result;
}

// / Applies a chain of override layers in sequence
// / Applies 一个 chain 的 override layers 在 sequence
// / base: the initial configuration
// / base: 初始 configuration
// / chain: slice of Overrides to apply in order (left to right)
// / chain: 切片 的 Overrides 到 apply 在 order (left 到 right)
// / Returns: final configuration after all layers are merged
// / 返回: 最终 configuration after 所有 layers are merged
fn apply(base: AppConfig, chain: []const Overrides) AppConfig {
    // Start with the base configuration
    // Start 使用 base configuration
    var current = base;
    
    // Apply each override layer in sequence
    // Apply 每个 override layer 在 sequence
    // Later layers override earlier ones
    for (chain) |layer| {
        current = merge(current, layer);
    }
    
    return current;
}

// / Helper function to print configuration values in a human-readable format
// / Helper 函数 到 打印 configuration 值 在 一个 human-readable format
// / writer: any type implementing write() and print() methods
// / writer: any 类型 implementing 写入() 和 打印() methods
// / label: descriptive text to identify this configuration dump
// / 标签: descriptive text 到 identify 此 configuration dump
// / config: the AppConfig instance to display
// / config: AppConfig instance 到 显示
fn printSummary(writer: anytype, label: []const u8, config: AppConfig) !void {
    try writer.print("{s}:\n", .{label});
    try writer.print("  host = {s}\n", .{config.host});
    try writer.print("  port = {}\n", .{config.port});
    try writer.print("  log = {s}\n", .{@tagName(config.log_level)});
    try writer.print("  instrumentation = {}\n", .{config.instrumentation});
    try writer.print("  theme = {s}\n", .{@tagName(config.theme)});
    try writer.print("  timeouts = {any}\n", .{config.timeouts});
}

pub fn main() !void {
    // Create base configuration with all default values
    // 创建 base configuration 使用 所有 默认 值
    const defaults = AppConfig{};
    
    // Define a profile-level override layer (e.g., development profile)
    // 定义一个 profile-level override layer (e.g., development profile)
    // This might come from a profile file or environment-specific settings
    // 此 might come 从 一个 profile 文件 或 environment-specific settings
    const profile = Overrides{
        .host = "0.0.0.0",
        .port = 9000,
        .log_level = .debug,
        .instrumentation = true,
        .theme = .dark,
        .timeouts = AppConfig.Timeouts{
            .connect_ms = 100,
            .read_ms = 1500,
        },
    };
    
    // Define environment-level overrides (e.g., from environment variables)
    // 定义 environment-level overrides (e.g., 从 environment variables)
    // These override profile settings
    // 这些 override profile settings
    const env = Overrides{
        .host = "config.internal",
        .port = 9443,
        .log_level = .warn,
        .timeouts = AppConfig.Timeouts{
            .connect_ms = 60,
            .read_ms = 1100,
        },
    };
    
    // Define command-line overrides (highest priority)
    // 定义 command-line overrides (highest priority)
    // Only overrides specific fields, leaving others unchanged
    const command_line = Overrides{
        .instrumentation = false,
        .theme = .light,
    };

    // Apply all override layers in precedence order:
    // Apply 所有 override layers 在 precedence order:
    // defaults -> profile -> env -> command_line
    // Later layers take precedence over earlier ones
    const final = apply(defaults, &[_]Overrides{ profile, env, command_line });

    // Set up buffered stdout writer to reduce syscalls
    // Set up 缓冲 stdout writer 到 reduce syscalls
    var stdout_buffer: [2048]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    
    // Display progression of configuration through each layer
    // 显示 progression 的 configuration through 每个 layer
    try printSummary(stdout, "defaults", defaults);
    try printSummary(stdout, "profile", merge(defaults, profile));
    try printSummary(stdout, "env", merge(defaults, env));
    try printSummary(stdout, "command_line", merge(defaults, command_line));
    
    // Add separator before showing final resolved config
    // Add separator before showing 最终 resolved config
    try stdout.writeByte('\n');
    
    // Display the final merged configuration after all layers applied
    // 显示 最终 merged configuration after 所有 layers applied
    try printSummary(stdout, "resolved", final);
    
    // Ensure all buffered output is written
    // 确保 所有 缓冲 输出 is written
    try stdout.flush();
}
