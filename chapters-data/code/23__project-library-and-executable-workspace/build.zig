const std = @import("std");

pub fn build(b: *std.Build) void {
    // Standard target and optimization options
    // 标准 target 和 optimization options
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    
    // ===== LIBRARY =====
    // ===== 库 =====
    // Create the TextKit library module
    // 创建 TextKit 库 module
    const textkit_mod = b.addModule("textkit", .{
        .root_source_file = b.path("src/textkit.zig"),
        .target = target,
    });
    
    // Build static library artifact
    // 构建 static 库 artifact
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
    
    // Install the library (to zig-out/lib/)
    // Install 库 (到 zig-out/lib/)
    b.installArtifact(lib);
    
    // ===== EXECUTABLE =====
    // Create executable that uses the library
    // 创建 executable 该 使用 库
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
    
    // Install the executable (to zig-out/bin/)
    // Install executable (到 zig-out/bin/)
    b.installArtifact(exe);
    
    // ===== RUN STEP =====
    // Create a run step for the executable
    // 创建可执行文件的运行步骤
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    
    // Forward command-line arguments to the application
    // 转发命令行参数到应用程序
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    
    const run_step = b.step("run", "Run the TextKit CLI");
    run_step.dependOn(&run_cmd.step);
    
    // ===== TESTS =====
    // Library tests
    // 库 tests
    const lib_tests = b.addTest(.{
        .root_module = textkit_mod,
    });
    
    const run_lib_tests = b.addRunArtifact(lib_tests);
    
    // Executable tests (minimal for main.zig)
    // Executable tests (最小化 用于 主.zig)
    const exe_tests = b.addTest(.{
        .root_module = exe.root_module,
    });
    
    const run_exe_tests = b.addRunArtifact(exe_tests);
    
    // Test step that runs all tests
    // 运行所有测试的测试步骤
    const test_step = b.step("test", "Run all tests");
    test_step.dependOn(&run_lib_tests.step);
    test_step.dependOn(&run_exe_tests.step);
    
    // ===== CUSTOM STEPS =====
    // ===== 自定义 STEPS =====
    // Demo step that shows usage
    // 展示用法的演示步骤
    const demo_step = b.step("demo", "Run demo commands");
    
    const demo_reverse = b.addRunArtifact(exe);
    demo_reverse.addArgs(&.{ "reverse", "Hello Zig!" });
    demo_step.dependOn(&demo_reverse.step);
    
    const demo_count = b.addRunArtifact(exe);
    demo_count.addArgs(&.{ "count", "mississippi", "s" });
    demo_step.dependOn(&demo_count.step);
}
