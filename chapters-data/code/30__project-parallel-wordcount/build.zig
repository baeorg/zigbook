const std = @import("std");

// / Build script for the parallel wordcount project.
// / 构建 script 用于 parallel wordcount project.
// / Configures and compiles the executable with standard build options.
// / Configures 和 compiles executable 使用 标准 构建 options.
pub fn build(b: *std.Build) void {
    // Parse target triple from command line (--target flag)
    // Parse target triple 从 命令行 (--target flag)
    const target = b.standardTargetOptions(.{});
    
    // Parse optimization level from command line (-Doptimize flag)
    // Parse optimization level 从 命令行 (-Doptimize flag)
    const optimize = b.standardOptimizeOption(.{});

    // Create a module representing our application's entry point.
    // 创建一个 module representing our application's 程序入口点.
    // In Zig 0.15.2, modules are explicitly created before being passed to executables.
    // 在 Zig 0.15.2, modules are explicitly created before being passed 到 executables.
    const root = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Define the executable artifact, linking it to the root module.
    // 定义 executable artifact, linking it 到 root module.
    const exe = b.addExecutable(.{
        .name = "parallel-wc",
        .root_module = root,
    });

    // Register the executable to be installed in zig-out/bin
    // Register executable 到 be installed 在 zig-out/bin
    b.installArtifact(exe);

    // Create a run command that executes the compiled binary
    // 创建一个 run command 该 executes compiled binary
    const run_cmd = b.addRunArtifact(exe);
    
    // Forward any arguments passed after '--' to the executable
    // Forward any arguments passed after '--' 到 executable
    if (b.args) |args| run_cmd.addArgs(args);

    // Define a 'run' step that users can invoke with 'zig build run'
    // 定义一个 'run' step 该 users can invoke 使用 'zig 构建 run'
    const run_step = b.step("run", "Run parallel wordcount");
    run_step.dependOn(&run_cmd.step);
}
