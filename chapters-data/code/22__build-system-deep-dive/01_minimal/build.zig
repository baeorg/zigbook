const std = @import("std");

// Minimal build.zig: single executable, no options
// 最小化 构建.zig: single executable, 不 options
// Demonstrates the simplest possible build script for the Zig build system.
// 演示 simplest possible 构建 script 用于 Zig 构建 system.
pub fn build(b: *std.Build) void {
    // Create an executable compilation step with minimal configuration.
    // 创建 一个 executable compilation step 使用 最小化 configuration.
    // This represents the fundamental pattern for producing a binary artifact.
    // 此 represents fundamental pattern 用于 producing 一个 binary artifact.
    const exe = b.addExecutable(.{
        // The output binary name (becomes "hello" or "hello.exe")
        // 输出 binary name (becomes "hello" 或 "hello.exe")
        .name = "hello",
        // Configure the root module with source file and compilation settings
        // Configure root module 使用 源文件 文件 和 compilation settings
        .root_module = b.createModule(.{
            // Specify the entry point source file relative to build.zig
            // Specify 程序入口点 源文件 文件 relative 到 构建.zig
            .root_source_file = b.path("main.zig"),
            // Target the host machine (the system running the build)
            // Target host machine ( system running 构建)
            .target = b.graph.host,
            // Use Debug optimization level (no optimizations, debug symbols included)
            // Use 调试 optimization level (不 optimizations, 调试 symbols included)
            .optimize = .Debug,
        }),
    });
    
    // Register the executable to be installed to the output directory.
    // Register executable 到 be installed 到 输出 directory.
    // When `zig build` runs, this artifact will be copied to zig-out/bin/
    // 当 `zig 构建` runs, 此 artifact will be copied 到 zig-out/bin/
    b.installArtifact(exe);
}
