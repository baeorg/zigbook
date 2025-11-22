// Import the standard library for build system types and utilities
// 导入标准库以获取构建系统类型和实用程序
const std = @import("std");

// Container struct that holds references to project modules
// 包含项目模块引用的容器结构体
// This allows centralized access to all workspace modules
// 这允许集中访问所有工作区模块
pub const Modules = struct {
    libA: *std.Build.Module,
    libB: *std.Build.Module,
};

// Creates and configures all project modules with their dependencies
// 创建和配置所有带有依赖项的项目模块
// This function sets up the module dependency graph for the workspace:
// 此函数为工作区设置模块依赖图：
// - palette: vendored external dependency
// - palette: 供应商提供的外部依赖项
// - libA: internal package with no dependencies
// - libA: 没有依赖项的内部包
// - libB: internal package that depends on both libA and palette
// - libB: 依赖于 libA 和 palette 的内部包
//
// Parameters:
// b: Build instance used to create modules
// b: 用于创建模块的构建实例
//   target: Compilation target (architecture, OS, ABI)
//   target: 编译目标 (架构, 操作系统, ABI)
// optimize: Optimization mode (Debug, ReleaseSafe, ReleaseFast, ReleaseSmall)
// optimize: 优化模式 (Debug, ReleaseSafe, ReleaseFast, ReleaseSmall)
//
// Returns: Modules struct containing references to libA and libB
// 返回: 包含 libA 和 libB 引用的 Modules 结构体
pub fn addModules(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) Modules {
    // Create module for the vendored palette library
    // 为供应商提供的 palette 库创建模块
    // Located in vendor directory as an external dependency
    // 作为外部依赖项位于 vendor 目录中
    const palette_mod = b.createModule(.{
        .root_source_file = b.path("vendor/palette/palette.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Create module for libA (analytics functionality)
    // 为 libA (分析功能) 创建模块
    // This is a standalone library with no external dependencies
    // 这是一个没有外部依赖项的独立库
    const lib_a = b.addModule("libA", .{
        .root_source_file = b.path("packages/libA/analytics.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Create module for libB (report functionality)
    // 为 libB (报告功能) 创建模块
    // Depends on both libA and palette, establishing the dependency chain
    // 依赖于 libA 和 palette，建立依赖链
    const lib_b = b.addModule("libB", .{
        .root_source_file = b.path("packages/libB/report.zig"),
        .target = target,
        .optimize = optimize,
        // Import declarations allow libB to access libA and palette modules
        // 导入声明允许 libB 访问 libA 和 palette 模块
        .imports = &.{
            .{ .name = "libA", .module = lib_a },
            .{ .name = "palette", .module = palette_mod },
        },
    });

    // Return configured modules for use in build scripts
    // 返回配置好的模块以在构建脚本中使用
    return Modules{
        .libA = lib_a,
        .libB = lib_b,
    };
}
