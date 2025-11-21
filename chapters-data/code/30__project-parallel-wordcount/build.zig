const std = @import("std");

// / Build script for the parallel wordcount project.
// / 并行词频统计项目的构建脚本。
// / Configures and compiles the executable with standard build options.
// / 使用标准构建选项配置和编译可执行文件。
pub fn build(b: *std.Build) void {
    // Parse target triple from command line (--target flag)
    // 从命令行解析目标三元组（--target 标志）
    const target = b.standardTargetOptions(.{});
    
    // Parse optimization level from command line (-Doptimize flag)
    // 从命令行解析优化级别（-Doptimize 标志）
    const optimize = b.standardOptimizeOption(.{});

    // Create a module representing our application's entry point.
    // 创建表示应用程序入口点的模块。
    // In Zig 0.15.2, modules are explicitly created before being passed to executables.
    // 在 Zig 0.15.2 中，模块在传递给可执行文件之前被显式创建。
    const root = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Define the executable artifact, linking it to the root module.
    // 定义可执行文件产物，将其链接到根模块。
    const exe = b.addExecutable(.{
        .name = "parallel-wc",
        .root_module = root,
    });

    // Register the executable to be installed in zig-out/bin
    // 注册可执行文件以安装到zig-out/bin
    b.installArtifact(exe);

    // Create a run command that executes the compiled binary
    // 创建执行已编译二进制文件的运行命令
    const run_cmd = b.addRunArtifact(exe);
    
    // Forward any arguments passed after '--' to the executable
    // 将在 '--' 之后传递的任何参数转发给可执行文件
    if (b.args) |args| run_cmd.addArgs(args);

    // Define a 'run' step that users can invoke with 'zig build run'
    // 定义用户可以通过 'zig build run' 调用的 'run' 步骤
    const run_step = b.step("run", "Run parallel wordcount");
    run_step.dependOn(&run_cmd.step);
}
