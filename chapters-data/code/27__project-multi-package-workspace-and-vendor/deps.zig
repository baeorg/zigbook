
// Import the standard library for build system types and utilities
// 导入标准库 用于 构建 system 类型 和 utilities
const std = @import("std");

// Container struct that holds references to project modules
// Container struct 该 holds references 到 project modules
// This allows centralized access to all workspace modules
// 此 allows centralized access 到 所有 workspace modules
pub const Modules = struct {
    libA: *std.Build.Module,
    libB: *std.Build.Module,
};

// Creates and configures all project modules with their dependencies
// Creates 和 configures 所有 project modules 使用 their dependencies
// This function sets up the module dependency graph for the workspace:
// 此 函数 sets up module dependency graph 用于 workspace:
// - palette: vendored external dependency
// - libA: internal package with no dependencies
// - libA: internal package 使用 不 dependencies
// - libB: internal package that depends on both libA and palette
// - libB: internal package 该 depends 在 both libA 和 palette
//
// Parameters:
// b: Build instance used to create modules
// b: 构建 instance used 到 创建 modules
//   target: Compilation target (architecture, OS, ABI)
// optimize: Optimization mode (Debug, ReleaseSafe, ReleaseFast, ReleaseSmall)
// optimize: Optimization 模式 (调试, ReleaseSafe, ReleaseFast, ReleaseSmall)
//
// Returns: Modules struct containing references to libA and libB
// 返回: Modules struct containing references 到 libA 和 libB
pub fn addModules(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) Modules {
    // Create module for the vendored palette library
    // 创建 module 用于 vendored palette 库
    // Located in vendor directory as an external dependency
    // Located 在 vendor directory 作为 一个 external dependency
    const palette_mod = b.createModule(.{
        .root_source_file = b.path("vendor/palette/palette.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Create module for libA (analytics functionality)
    // 创建 module 用于 libA (analytics functionality)
    // This is a standalone library with no external dependencies
    // 此 is 一个 standalone 库 使用 不 external dependencies
    const lib_a = b.addModule("libA", .{
        .root_source_file = b.path("packages/libA/analytics.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Create module for libB (report functionality)
    // 创建 module 用于 libB (report functionality)
    // Depends on both libA and palette, establishing the dependency chain
    // Depends 在 both libA 和 palette, establishing dependency chain
    const lib_b = b.addModule("libB", .{
        .root_source_file = b.path("packages/libB/report.zig"),
        .target = target,
        .optimize = optimize,
        // Import declarations allow libB to access libA and palette modules
        // 导入 declarations allow libB 以访问 libA 和 palette modules
        .imports = &.{
            .{ .name = "libA", .module = lib_a },
            .{ .name = "palette", .module = palette_mod },
        },
    });

    // Return configured modules for use in build scripts
    // 返回 configured modules 用于 use 在 构建 scripts
    return Modules{
        .libA = lib_a,
        .libB = lib_b,
    };
}
