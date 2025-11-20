const std = @import("std");

// Demonstrating custom build options
// Demonstrating 自定义 构建 options
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Custom boolean option
    // 自定义 boolean option
    const enable_logging = b.option(
        bool,
        "enable-logging",
        "Enable debug logging",
    ) orelse false;

    // Custom string option
    // 自定义 string option
    const app_name = b.option(
        []const u8,
        "app-name",
        "Application name",
    ) orelse "MyApp";

    // Create options module to pass config to code
    // 创建 options module 到 pass config 到 代码
    const config = b.addOptions();
    config.addOption(bool, "enable_logging", enable_logging);
    config.addOption([]const u8, "app_name", app_name);

    const config_module = config.createModule();

    const exe = b.addExecutable(.{
        .name = "configapp",
        .root_module = b.createModule(.{
            .root_source_file = b.path("main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "config", .module = config_module },
            },
        }),
    });

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
}
