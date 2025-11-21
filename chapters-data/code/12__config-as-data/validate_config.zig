const std = @import("std");

//  Environment mode for the application
//  应用程序的环境模式
//  Determines security requirements and runtime behavior
//  确定安全要求和运行时行为
const Mode = enum { development, staging, production };

//  Main application configuration structure with nested settings
//  带嵌套设置的主应用程序配置结构
const AppConfig = struct {
    host: []const u8 = "127.0.0.1",
    port: u16 = 8080,
    mode: Mode = .development,
    tls: Tls = .{},
    timeouts: Timeouts = .{},

    //  TLS/SSL configuration for secure connections
    //  用于安全连接的 TLS/SSL 配置
    pub const Tls = struct {
        enabled: bool = false,
        cert_path: ?[]const u8 = null,
        key_path: ?[]const u8 = null,
    };

    //  Timeout settings for network operations
    //  网络操作的超时设置
    pub const Timeouts = struct {
        connect_ms: u32 = 200,
        read_ms: u32 = 1200,
    };
};

//  Explicit error set for all configuration validation failures
//  所有配置验证失败的显式错误集合
//  Each variant represents a specific invariant violation
//  每个变体代表一个特定的不变式违反
const ConfigError = error{
    InvalidPort,
    InsecureProduction,
    MissingTlsMaterial,
    TimeoutOrdering,
};

//  Validates configuration invariants and business rules
//  验证配置不变式和业务规则
//  config: the configuration to validate
//  config: 要验证的配置
//  Returns: ConfigError if any validation rule is violated
//  返回：如果违反任何验证规则则返回 ConfigError
fn validate(config: AppConfig) ConfigError!void {
    // Port 0 is reserved and invalid for network binding
    // 端口0是保留的，用于网络绑定无效
    if (config.port == 0) return error.InvalidPort;

    // Ports below 1024 require elevated privileges (except standard HTTPS)
    // 1024以下的端口需要提升权限（标准HTTPS除外）
    // Reject them to avoid privilege escalation requirements
    // 拒绝它们以避免权限提升要求
    if (config.port < 1024 and config.port != 443) return error.InvalidPort;

    // Production environments must enforce TLS to protect data in transit
    // 生产环境必须强制使用TLS以保护传输中的数据
    if (config.mode == .production and !config.tls.enabled) {
        return error.InsecureProduction;
    }

    // When TLS is enabled, both certificate and private key must be provided
    // 当启用TLS时，必须同时提供证书和私钥
    if (config.tls.enabled) {
        if (config.tls.cert_path == null or config.tls.key_path == null) {
            return error.MissingTlsMaterial;
        }
    }

    // Read timeout must exceed connect timeout to allow data transfer
    // 读取超时必须超过连接超时以允许数据传输
    // Otherwise connections would time out immediately after establishment
    // 否则连接会在建立后立即超时
    if (config.timeouts.read_ms < config.timeouts.connect_ms) {
        return error.TimeoutOrdering;
    }
}

// / Reports validation result in human-readable format
// / 以人类可读格式报告验证结果
// / writer: output destination for the report
// / writer: 报告的输出目标
// / label: descriptive name for this configuration test case
// / label: 此配置测试用例的描述性名称
// / config: the configuration to validate and report on
// / config: 要验证和报告的配置
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
    // 设置缓冲stdout写入器以减少系统调用
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
    // 确保所有缓冲输出写入stdout
    try stdout.flush();
}
