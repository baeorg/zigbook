const std = @import("std");

pub fn build(b: *std.Build) void {
    // Standard target and optimization options allow the build to be configured
    // 标准 target 和 optimization options allow 构建 到 be configured
    // for different architectures and optimization levels via CLI flags
    // 用于 different architectures 和 optimization levels via 命令行工具 flags
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Create the analytics module - the foundational module that provides
    // 创建 analytics module - foundational module 该 provides
    // core metric calculation and analysis capabilities
    // core metric calculation 和 analysis capabilities
    const analytics_mod = b.addModule("analytics", .{
        .root_source_file = b.path("workspace/analytics/lib.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Create the reporting module - depends on analytics to format and display metrics
    // 创建 reporting module - depends 在 analytics 到 format 和 显示 metrics
    // Uses addModule() which both creates and registers the module in one step
    // 使用 addModule() which both creates 和 registers module 在 一个 step
    const reporting_mod = b.addModule("reporting", .{
        .root_source_file = b.path("workspace/reporting/lib.zig"),
        .target = target,
        .optimize = optimize,
        // Import analytics module to access metric types and computation functions
        // 导入 analytics module 以访问 metric 类型 和 computation 函数
        .imports = &.{.{ .name = "analytics", .module = analytics_mod }},
    });

    // Create the adapters module using createModule() - creates but does not register
    // 创建 adapters module 使用 createModule() - creates but does 不 register
    // This demonstrates an anonymous module that other code can import but won't
    // 此 演示 一个 anonymous module 该 other 代码 can 导入 but won't
    // appear in the global module namespace
    // appear 在 global module namespace
    const adapters_mod = b.createModule(.{
        .root_source_file = b.path("workspace/adapters/vendored.zig"),
        .target = target,
        .optimize = optimize,
        // Adapters need analytics to serialize metric data
        // Adapters need analytics 到 serialize metric 数据
        .imports = &.{.{ .name = "analytics", .module = analytics_mod }},
    });

    // Create the main application module that orchestrates all dependencies
    // 创建 主 application module 该 orchestrates 所有 dependencies
    // This demonstrates how a root module can compose multiple imported modules
    // 此 演示 how 一个 root module can compose multiple imported modules
    const app_module = b.createModule(.{
        .root_source_file = b.path("workspace/app/main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            // Import all three workspace modules to access their functionality
            // 导入 所有 三个 workspace modules 以访问 their functionality
            .{ .name = "analytics", .module = analytics_mod },
            .{ .name = "reporting", .module = reporting_mod },
            .{ .name = "adapters", .module = adapters_mod },
        },
    });

    // Create the executable artifact using the composed app module as its root
    // 创建 executable artifact 使用 composed app module 作为 its root
    // The root_module field replaces the legacy root_source_file approach
    // root_module field replaces legacy root_source_file approach
    const exe = b.addExecutable(.{
        .name = "workspace-app",
        .root_module = app_module,
    });

    // Install the executable to zig-out/bin so it can be run after building
    // Install executable 到 zig-out/bin so it can be run after building
    b.installArtifact(exe);

    // Set up a run command that executes the built executable
    // Set up 一个 run command 该 executes built executable
    const run_cmd = b.addRunArtifact(exe);
    // Forward any command-line arguments passed to the build system to the executable
    // Forward any command-line arguments passed 到 构建 system 到 executable
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // Create a custom build step "run" that users can invoke with `zig build run`
    // 创建一个 自定义 构建 step "run" 该 users can invoke 使用 `zig 构建 run`
    const run_step = b.step("run", "Run workspace app with registered modules");
    run_step.dependOn(&run_cmd.step);

    // Create a named write files step to document the module dependency graph
    // 创建一个 named 写入 文件 step 到 document module dependency graph
    // This is useful for understanding the workspace structure without reading code
    // 此 is useful 用于 understanding workspace structure without reading 代码
    const graph_files = b.addNamedWriteFiles("graph");
    // Generate a text file documenting the module registration hierarchy
    // Generate 一个 text 文件 documenting module registration hierarchy
    _ = graph_files.add("module-graph.txt",
        \\workspace module registration map:
        \\  analytics  -> workspace/analytics/lib.zig
        \\  reporting  -> workspace/reporting/lib.zig (imports analytics)
        \\  adapters   -> (anonymous) workspace/adapters/vendored.zig
        \\  exe root   -> workspace/app/main.zig
    );

    // Create a custom build step "graph" that generates module documentation
    // 创建一个 自定义 构建 step "graph" 该 generates module 文档
    // Users can invoke this with `zig build graph` to output the dependency map
    // Users can invoke 此 使用 `zig 构建 graph` 到 输出 dependency map
    const graph_step = b.step("graph", "Emit module graph summary to zig-out");
    graph_step.dependOn(&graph_files.step);
}
