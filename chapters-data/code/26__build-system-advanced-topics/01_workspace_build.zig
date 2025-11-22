const std = @import("std");

pub fn build(b: *std.Build) void {
    // 标准目标和优化选项允许通过CLI标志配置构建
    // 用于不同的架构和优化级别
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // 创建analytics模块 - 提供核心度量计算和分析功能的基础模块
    const analytics_mod = b.addModule("analytics", .{
        .root_source_file = b.path("workspace/analytics/lib.zig"),
        .target = target,
        .optimize = optimize,
    });

    // 创建reporting模块 - 依赖analytics来格式化和显示度量
    // 使用addModule()一步创建和注册模块
    const reporting_mod = b.addModule("reporting", .{
        .root_source_file = b.path("workspace/reporting/lib.zig"),
        .target = target,
        .optimize = optimize,
        // 导入analytics模块以访问度量类型和计算函数
        .imports = &.{.{ .name = "analytics", .module = analytics_mod }},
    });

    // 使用createModule()创建adapters模块 - 创建但不注册
    // 这演示了一个匿名模块，其他代码可以导入但不会
    // 出现在全局模块命名空间中
    const adapters_mod = b.createModule(.{
        .root_source_file = b.path("workspace/adapters/vendored.zig"),
        .target = target,
        .optimize = optimize,
        // Adapters需要analytics来序列化度量数据
        .imports = &.{.{ .name = "analytics", .module = analytics_mod }},
    });

    // 创建编排所有依赖的主应用程序模块
    // 这演示了根模块如何组合多个导入的模块
    const app_module = b.createModule(.{
        .name = "app", // 给模块一个名字
        .root_source_file = b.path("workspace/app/main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            // 导入所有三个工作区模块以访问其功能
            .{ .name = "analytics", .module = analytics_mod },
            .{ .name = "reporting", .module = reporting_mod },
            .{ .name = "adapters", .module = adapters_mod },
        },
    });

    // 使用组合的app模块作为其根创建可执行文件
    // root_module字段替换了传统的root_source_file方法
    const exe = b.addExecutable(.{
        .name = "workspace-app",
        .root_module = app_module,
    });

    // 将可执行文件安装到zig-out/bin，以便构建后可以运行
    b.installArtifact(exe);

    // 设置执行构建可执行文件的运行命令
    const run_cmd = b.addRunArtifact(exe);
    // 转发传递给构建系统的任何命令行参数到可执行文件
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // 创建自定义构建步骤"run"，用户可以使用`zig build run`调用
    const run_step = b.step("run", "Run workspace app with registered modules");
    run_step.dependOn(&run_cmd.step);

    // 创建命名写入文件步骤来记录模块依赖关系图
    // 这有助于理解工作区结构而不读取代码
    const graph_files = b.addNamedWriteFiles("graph");
    // 生成记录模块注册层次结构的文本文件
    _ = graph_files.add("module-graph.txt",
        \\workspace module registration map:
        \\  analytics  -> workspace/analytics/lib.zig
        \\  reporting  -> workspace/reporting/lib.zig (imports analytics)
        \\  adapters   -> (anonymous) workspace/adapters/vendored.zig
        \\  exe root   -> workspace/app/main.zig
    );

    // 创建自定义构建步骤"graph"，生成模块文档
    // 用户可以使用`zig build graph`调用此步骤来输出依赖关系图
    const graph_step = b.step("graph", "Emit module graph summary to zig-out");
    graph_step.dependOn(&graph_files.step);
}
