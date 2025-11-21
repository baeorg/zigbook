const std = @import("std");
const deps = @import("deps.zig");

/// 多包工作区的构建脚本，演示依赖项管理。
/// 编排依赖于本地包（libA、libB）
/// 和 vendored 依赖项（palette）的可执行文件的编译，并提供测试和文档步骤。
pub fn build(b: *std.Build) void {
    // 从命令行选项解析目标平台和优化级别
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // 通过deps.zig加载所有工作区模块（libA、libB、palette）
    // 这集中了依赖项配置并使模块可用于导入
    const modules = deps.addModules(b, target, optimize);

    // 创建主可执行文件的根模块
    // 显式声明对libA和libB的依赖，使其可导入
    const root_module = b.createModule(.{
        .root_source_file = b.path("app/main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            // 将导入名称映射到从deps.zig加载的实际模块
            .{ .name = "libA", .module = modules.libA },
            .{ .name = "libB", .module = modules.libB },
        },
    });

    // 使用配置的根模块定义可执行文件工件
    const exe = b.addExecutable(.{
        .name = "workspace-dashboard",
        .root_module = root_module,
    });

    // 注册可执行文件以安装到zig-out/bin
    b.installArtifact(exe);

    // 创建运行构建可执行文件的命令
    const run_cmd = b.addRunArtifact(exe);
    // 将任何额外的命令行参数转发到可执行文件
    if (b.args) |args| run_cmd.addArgs(args);

    // 注册"zig build run"步骤以编译并执行仪表板
    const run_step = b.step("run", "Run the latency dashboard");
    run_step.dependOn(&run_cmd.step);

    // 为每个库模块创建测试可执行文件
    // 这些将运行在相应库源文件中定义的任何测试
    const lib_a_tests = b.addTest(.{ .root_module = modules.libA });
    const lib_b_tests = b.addTest(.{ .root_module = modules.libB });

    // 注册"zig build test"步骤以运行所有库测试套件
    const tests_step = b.step("test", "Run library test suites");
    tests_step.dependOn(&b.addRunArtifact(lib_a_tests).step);
    tests_step.dependOn(&b.addRunArtifact(lib_b_tests).step);

    // 生成记录工作区模块结构的文本文件
    // 这作为依赖关系图的人类可读文档
    const mapping = b.addNamedWriteFiles("workspace-artifacts");
    _ = mapping.add("dependency-map.txt",
        \\Modules registered in build.zig:
        \\  libA      -> packages/libA/analytics.zig
        \\  libB      -> packages/libB/report.zig (imports libA, palette)
        \\  palette   -> vendor/palette/palette.zig (anonymous)
        \\  executable -> app/main.zig
    );

    // 将生成的文档安装到zig-out/workspace-artifacts
    const install_map = b.addInstallDirectory(.{
        .source_dir = mapping.getDirectory(),
        .install_dir = .prefix,
        .install_subdir = "workspace-artifacts",
    });

    // 注册"zig build map"步骤以生成并安装依赖项文档
    const map_step = b.step("map", "Emit dependency map to zig-out");
    map_step.dependOn(&install_map.step);
}
