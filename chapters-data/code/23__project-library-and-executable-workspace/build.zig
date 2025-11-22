const std = @import("std");

pub fn build(b: *std.Build) void {
    // 标准目标和优化选项
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    
    // ===== 库 =====
    // 创建 TextKit 库模块
    const textkit_mod = b.addModule("textkit", .{
        .root_source_file = b.path("src/textkit.zig"),
        .target = target,
    });
    
    // 构建静态库产物
    const lib = b.addLibrary(.{
        .name = "textkit",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/textkit.zig"),
            .target = target,
            .optimize = optimize,
        }),
        .version = .{ .major = 1, .minor = 0, .patch = 0 },
        .linkage = .static,
    });
    
    // 安装库 (到 zig-out/lib/)
    b.installArtifact(lib);
    
    // ===== 可执行文件 =====
    // 创建使用库的可执行文件
    const exe = b.addExecutable(.{
        .name = "textkit-cli",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "textkit", .module = textkit_mod },
            },
        }),
    });
    
    // 安装可执行文件 (到 zig-out/bin/)
    b.installArtifact(exe);
    
    // ===== 运行步骤 =====
    // 创建可执行文件的运行步骤
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    
    // 转发命令行参数到应用程序
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    
    const run_step = b.step("run", "Run the TextKit CLI");
    run_step.dependOn(&run_cmd.step);
    
    // ===== 测试 =====
    // 库测试
    const lib_tests = b.addTest(.{
        .root_module = textkit_mod,
    });
    
    const run_lib_tests = b.addRunArtifact(lib_tests);
    
    // 可执行文件测试 (main.zig 的最小测试)
    const exe_tests = b.addTest(.{
        .root_module = exe.root_module,
    });
    
    const run_exe_tests = b.addRunArtifact(exe_tests);
    
    // 运行所有测试的测试步骤
    const test_step = b.step("test", "Run all tests");
    test_step.dependOn(&run_lib_tests.step);
    test_step.dependOn(&run_exe_tests.step);
    
    // ===== 自定义步骤 =====
    // 展示用法的演示步骤
    const demo_step = b.step("demo", "Run demo commands");
    
    const demo_reverse = b.addRunArtifact(exe);
    demo_reverse.addArgs(&.{ "reverse", "Hello Zig!" });
    demo_step.dependOn(&demo_reverse.step);
    
    const demo_count = b.addRunArtifact(exe);
    demo_count.addArgs(&.{ "count", "mississippi", "s" });
    demo_step.dependOn(&demo_count.step);
}
