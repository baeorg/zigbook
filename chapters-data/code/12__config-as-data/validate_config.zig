const std = @import("std");

// / Environment mode for the application
// / Environment 模式 用于 application
// / Determines security requirements and runtime behavior
// / Determines security requirements 和 runtime behavior
const Mode = enum { development, staging, production };

// / Main application configuration structure with nested settings
// / 主 application configuration structure 使用 nested settings
const AppConfig = struct {
    host: []const u8 = "127.0.0.1",
    port: u16 = 8080,
    mode: Mode = .development,
    tls: Tls = .{},
    timeouts: Timeouts = .{},

    // / TLS/SSL configuration for secure connections
    // / TLS/SSL configuration 用于 secure connections
    pub const Tls = struct {
        enabled: bool = false,
        cert_path: ?[]const u8 = null,
        key_path: ?[]const u8 = null,
    };

    // / Timeout settings for network operations
    // / Timeout settings 用于 network operations
    pub const Timeouts = struct {
        connect_ms: u32 = 200,
        read_ms: u32 = 1200,
    };
};

// / Explicit error set for all configuration validation failures
// / Explicit 错误集合 用于 所有 configuration validation failures
// / Each variant represents a specific invariant violation
// / 每个 variant represents 一个 specific invariant violation
const ConfigError = error{
    InvalidPort,
    InsecureProduction,
    MissingTlsMaterial,
    TimeoutOrdering,
};

// / Validates configuration invariants and business rules
// / Validates configuration invariants 和 business rules
// / config: the configuration to validate
// / config: configuration 到 验证
// / Returns: ConfigError if any validation rule is violated
// / 返回: ConfigError 如果 any validation rule is violated
fn validate(config: AppConfig) ConfigError!void {
    // Port 0 is reserved and invalid for network binding
    // Port 0 is reserved 和 无效 用于 network binding
    if (config.port == 0) return error.InvalidPort;
    
    // Ports below 1024 require elevated privileges (except standard HTTPS)
    // Ports below 1024 require elevated privileges (except 标准 HTTPS)
    // Reject them to avoid privilege escalation requirements
    // Reject them 到 avoid privilege escalation requirements
    if (config.port < 1024 and config.port != 443) return error.InvalidPort;

    // Production environments must enforce TLS to protect data in transit
    // Production environments must enforce TLS 到 protect 数据 在 transit
    if (config.mode == .production and !config.tls.enabled) {
        return error.InsecureProduction;
    }

    // When TLS is enabled, both certificate and private key must be provided
    // 当 TLS is enabled, both certificate 和 private key must be provided
    if (config.tls.enabled) {
        if (config.tls.cert_path == null or config.tls.key_path == null) {
            return error.MissingTlsMaterial;
        }
    }

    // Read timeout must exceed connect timeout to allow data transfer
    // 读取 timeout must exceed connect timeout 到 allow 数据 transfer
    // Otherwise connections would time out immediately after establishment
    if (config.timeouts.read_ms < config.timeouts.connect_ms) {
        return error.TimeoutOrdering;
    }
}

// / Reports validation result in human-readable format
// / Reports validation result 在 human-readable format
// / writer: output destination for the report
// / writer: 输出 目标文件 用于 report
// / label: descriptive name for this configuration test case
// / 标签: descriptive name 用于 此 configuration test case
// / config: the configuration to validate and report on
// / config: configuration 到 验证 和 report 在
fn report(writer: anytype, label: []const u8, config: AppConfig) !void {
    try writer.print("{s}: ", .{label});
    
    // Attempt validation and catch any errors
    // 尝试 validation 和 捕获 any 错误
    validate(config) catch |err| {
        // If validation fails, report the error name and return
        // 如果 validation fails, report 错误 name 和 返回
        return try writer.print("error {s}\n", .{@errorName(err)});
    };
    
    // If validation succeeded, report success
    // 如果 validation succeeded, report 成功
    try writer.print("ok\n", .{});
}

pub fn main() !void {
    // Test case 1: Valid production configuration
    // All security requirements met: TLS enabled with credentials
    // 所有 security requirements met: TLS enabled 使用 credentials
    const production = AppConfig{
        .host = "example.com",
        .port = 8443,
        .mode = .production,
        .tls = .{
            .enabled = true,
            .cert_path = "certs/app.pem",
            .key_path = "certs/app.key",
        },
        .timeouts = .{
            .connect_ms = 250,
            .read_ms = 1800,
        },
    };

    // Test case 2: Invalid - production mode without TLS
    // Test case 2: 无效 - production 模式 without TLS
    // Should trigger InsecureProduction error
    // Should trigger InsecureProduction 错误
    const insecure = AppConfig{
        .mode = .production,
        .tls = .{ .enabled = false },
    };

    // Test case 3: Invalid - read timeout less than connect timeout
    // Test case 3: 无效 - 读取 timeout less than connect timeout
    // Should trigger TimeoutOrdering error
    // Should trigger TimeoutOrdering 错误
    const misordered = AppConfig{
        .timeouts = .{
            .connect_ms = 700,
            .read_ms = 500,
        },
    };

    // Test case 4: Invalid - TLS enabled but missing certificate
    // Test case 4: 无效 - TLS enabled but 缺失 certificate
    // Should trigger MissingTlsMaterial error
    // Should trigger MissingTlsMaterial 错误
    const missing_tls_material = AppConfig{
        .mode = .staging,
        .tls = .{
            .enabled = true,
            .cert_path = null,
            .key_path = "certs/dev.key",
        },
    };

    // Set up buffered stdout writer to reduce syscalls
    // Set up 缓冲 stdout writer 到 reduce syscalls
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    
    // Run validation reports for all test cases
    // Run validation reports 用于 所有 test 情况
    // Each report will validate the config and print the result
    // 每个 report will 验证 config 和 打印 result
    try report(stdout, "production", production);
    try report(stdout, "insecure", insecure);
    try report(stdout, "misordered", misordered);
    try report(stdout, "missing_tls_material", missing_tls_material);
    
    // Ensure all buffered output is written to stdout
    // 确保 所有 缓冲 输出 is written 到 stdout
    try stdout.flush();
}
