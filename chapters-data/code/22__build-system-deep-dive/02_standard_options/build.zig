const std = @import("std");

// Demonstrating standardTargetOptions and standardOptimizeOption
// Demonstrating standardTargetOptions 和 standardOptimizeOption
pub fn build(b: *std.Build) void {
    // Allows user to choose target: zig build -Dtarget=x86_64-linux
    // 允许用户选择 target: zig 构建 -Dtarget=x86_64-linux
    const target = b.standardTargetOptions(.{});
    
    // Allows user to choose optimization: zig build -Doptimize=ReleaseFast
    // 允许用户选择 optimization: zig 构建 -Doptimize=ReleaseFast
    const optimize = b.standardOptimizeOption(.{});
    
    const exe = b.addExecutable(.{
        .name = "configurable",
        .root_module = b.createModule(.{
            .root_source_file = b.path("main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    
    b.installArtifact(exe);
    
    // Add run step
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    
    const run_step = b.step("run", "Run the application");
    run_step.dependOn(&run_cmd.step);
}
