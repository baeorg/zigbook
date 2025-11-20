const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Core dependency is always loaded
    const core_dep = b.dependency("core", .{
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "app",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    exe.root_module.addImport("core", core_dep.module("core"));
    b.installArtifact(exe);

    // Conditionally use lazy dependencies based on build options
    // Conditionally use lazy dependencies 基于 构建 options
    const enable_benchmarks = b.option(bool, "benchmarks", "Enable benchmark mode") orelse false;
    const enable_debug_viz = b.option(bool, "debug-viz", "Enable debug visualizations") orelse false;

    if (enable_benchmarks) {
        // lazyDependency returns null if not yet fetched
        // lazyDependency 返回 空 如果 不 yet fetched
        if (b.lazyDependency("benchmark_utils", .{
            .target = target,
            .optimize = optimize,
        })) |bench_dep| {
            exe.root_module.addImport("benchmark", bench_dep.module("benchmark"));
        }
    }

    if (enable_debug_viz) {
        if (b.lazyDependency("debug_visualizer", .{
            .target = target,
            .optimize = optimize,
        })) |viz_dep| {
            exe.root_module.addImport("visualizer", viz_dep.module("visualizer"));
        }
    }

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
