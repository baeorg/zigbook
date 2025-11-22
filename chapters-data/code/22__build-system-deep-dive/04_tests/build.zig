const std = @import("std");

// 演示测试集成
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    
    const lib_mod = b.addModule("mylib", .{
        .root_source_file = b.path("lib.zig"),
        .target = target,
    });
    
    // 为库模块创建测试
    const lib_tests = b.addTest(.{
        .root_module = lib_mod,
    });
    
    const run_lib_tests = b.addRunArtifact(lib_tests);
    
    // 创建测试步骤
    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&run_lib_tests.step);
    
    // 同时创建一个使用该库的可执行文件
    const exe = b.addExecutable(.{
        .name = "app",
        .root_module = b.createModule(.{
            .root_source_file = b.path("main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "mylib", .module = lib_mod },
            },
        }),
    });
    
    b.installArtifact(exe);
}
