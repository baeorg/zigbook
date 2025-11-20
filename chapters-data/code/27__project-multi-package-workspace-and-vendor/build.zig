const std = @import("std");
const deps = @import("deps.zig");

// / Build script for a multi-package workspace demonstrating dependency management.
// / 构建 script 用于 一个 multi-package workspace demonstrating dependency management.
// / Orchestrates compilation of an executable that depends on local packages (libA, libB)
// / Orchestrates compilation 的 一个 executable 该 depends 在 local packages (libA, libB)
// / and a vendored dependency (palette), plus provides test and documentation steps.
// / 和 一个 vendored dependency (palette), plus provides test 和 文档 steps.
pub fn build(b: *std.Build) void {
    // Parse target platform and optimization level from command-line options
    // Parse target platform 和 optimization level 从 command-line options
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Load all workspace modules (libA, libB, palette) via deps.zig
    // Load 所有 workspace modules (libA, libB, palette) via deps.zig
    // This centralizes dependency configuration and makes modules available for import
    // 此 centralizes dependency configuration 和 makes modules available 用于 导入
    const modules = deps.addModules(b, target, optimize);

    // Create the root module for the main executable
    // 创建 root module 用于 主 executable
    // Explicitly declares dependencies on libA and libB, making them importable
    // Explicitly declares dependencies 在 libA 和 libB, making them importable
    const root_module = b.createModule(.{
        .root_source_file = b.path("app/main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            // Map import names to actual modules loaded from deps.zig
            // Map 导入 names 到 actual modules loaded 从 deps.zig
            .{ .name = "libA", .module = modules.libA },
            .{ .name = "libB", .module = modules.libB },
        },
    });

    // Define the executable artifact using the configured root module
    // 定义 executable artifact 使用 configured root module
    const exe = b.addExecutable(.{
        .name = "workspace-dashboard",
        .root_module = root_module,
    });

    // Register the executable for installation into zig-out/bin
    // Register executable 用于 installation into zig-out/bin
    b.installArtifact(exe);

    // Create a command to run the built executable
    // 创建一个 command 到 run built executable
    const run_cmd = b.addRunArtifact(exe);
    // Forward any extra command-line arguments to the executable
    // Forward any extra command-line arguments 到 executable
    if (b.args) |args| run_cmd.addArgs(args);

    // Register "zig build run" step to compile and execute the dashboard
    // Register "zig 构建 run" step 到 编译 和 execute dashboard
    const run_step = b.step("run", "Run the latency dashboard");
    run_step.dependOn(&run_cmd.step);

    // Create test executables for each library module
    // 创建 test executables 用于 每个 库 module
    // These will run any tests defined in the respective library source files
    // 这些 will run any tests defined 在 respective 库 源文件 文件
    const lib_a_tests = b.addTest(.{ .root_module = modules.libA });
    const lib_b_tests = b.addTest(.{ .root_module = modules.libB });

    // Register "zig build test" step to run all library test suites
    // Register "zig 构建 test" step 到 run 所有 库 test suites
    const tests_step = b.step("test", "Run library test suites");
    tests_step.dependOn(&b.addRunArtifact(lib_a_tests).step);
    tests_step.dependOn(&b.addRunArtifact(lib_b_tests).step);

    // Generate a text file documenting the workspace module structure
    // Generate 一个 text 文件 documenting workspace module structure
    // This serves as human-readable documentation of the dependency graph
    // 此 serves 作为 human-readable 文档 的 dependency graph
    const mapping = b.addNamedWriteFiles("workspace-artifacts");
    _ = mapping.add("dependency-map.txt",
        \\Modules registered in build.zig:
        \\  libA      -> packages/libA/analytics.zig
        \\  libB      -> packages/libB/report.zig (imports libA, palette)
        \\  palette   -> vendor/palette/palette.zig (anonymous)
        \\  executable -> app/main.zig
    );

    // Install the generated documentation into zig-out/workspace-artifacts
    // Install generated 文档 into zig-out/workspace-artifacts
    const install_map = b.addInstallDirectory(.{
        .source_dir = mapping.getDirectory(),
        .install_dir = .prefix,
        .install_subdir = "workspace-artifacts",
    });

    // Register "zig build map" step to generate and install dependency documentation
    // Register "zig 构建 map" step 到 generate 和 install dependency 文档
    const map_step = b.step("map", "Emit dependency map to zig-out");
    map_step.dependOn(&install_map.step);
}
