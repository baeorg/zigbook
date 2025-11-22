const std = @import("std");

// 演示模块创建和导入
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    
    // 创建一个可重用模块（public）
    const math_mod = b.addModule("math", .{
        .root_source_file = b.path("math.zig"),
        .target = target,
    });
    
    // 使用导入的模块创建可执行文件
    const exe = b.addExecutable(.{
        .name = "calculator",
        .root_module = b.createModule(.{
            .root_source_file = b.path("main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "math", .module = math_mod },
            },
        }),
    });
    
    b.installArtifact(exe);
    
    const run_step = b.step("run", "Run the calculator");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
}
