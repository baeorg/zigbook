const std = @import("std");

// 最小化的 build.zig：单个可执行文件，无选项
// 演示 Zig 构建系统中最简单的构建脚本。
pub fn build(b: *std.Build) void {
    // 使用最简配置创建一个可执行文件编译步骤。
    // 这代表了生成二进制产物的基本模式。
    const exe = b.addExecutable(.{
        // 输出的二进制文件名（将变为 "hello" 或 "hello.exe"）
        .name = "hello",
        // 配置根模块的源文件和编译设置
        .root_module = b.createModule(.{
            // 指定相对于 build.zig 的入口点源文件
            .root_source_file = b.path("main.zig"),
            // 目标为宿主机（运行构建的系统）
            .target = b.graph.host,
            // 使用Debug优化级别（无优化，包含调试符号）
            .optimize = .Debug,
        }),
    });
    
    // 注册可执行文件以安装到输出目录。
    // 运行 `zig build` 时，此产物将被复制到 zig-out/bin/。
    b.installArtifact(exe);
}
