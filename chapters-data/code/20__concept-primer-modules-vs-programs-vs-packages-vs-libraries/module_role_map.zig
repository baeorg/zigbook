
// This module demonstrates how Zig's module system distinguishes between different roles:
// 此 module 演示 how Zig's module system distinguishes between different roles:
// programs (with main), libraries (exposing public APIs), and hybrid modules.
// programs (使用 主), libraries (exposing public APIs), 和 hybrid modules.
// It showcases introspection of module characteristics and role-based decision making.
// It showcases introspection 的 module characteristics 和 role-based decision making.

const std = @import("std");
const roles = @import("role_checks.zig");
const manifest_pkg = @import("pkg/manifest.zig");

// / List of public declarations intentionally exported by the root module.
// / List 的 public declarations intentionally exported 通过 root module.
// / This array defines the public API surface that other modules can rely on.
// / 此 数组 defines public API surface 该 other modules can rely 在.
// / It serves as documentation and can be used for validation or tooling.
// / It serves 作为 文档 和 can be used 用于 validation 或 tooling.
pub const PublicSurface = [_][]const u8{
    "main",
    "libraryManifest",
    "PublicSurface",
};

// / Provide a canonical manifest describing the library surface that this module exposes.
// / Provide 一个 canonical manifest describing 库 surface 该 此 module exposes.
// / Other modules import this helper to reason about the package-level API.
// / Other modules 导入 此 helper 到 reason about package-level API.
// / Returns a Manifest struct containing metadata about the library's public interface.
// / 返回 一个 Manifest struct containing metadata about 库's public 接口.
pub fn libraryManifest() manifest_pkg.Manifest {
    // Delegate to the manifest package to construct a sample library descriptor
    // Delegate 到 manifest package 到 construct 一个 sample 库 descriptor
    return manifest_pkg.sampleLibrary();
}

// / Entry point demonstrating module role classification and vocabulary.
// / 程序入口点 demonstrating module role 分类 和 vocabulary.
// / Analyzes both the root module and a library module, printing their characteristics:
// / Analyzes both root module 和 一个 库 module, printing their characteristics:
// / - Whether they export a main function (indicating program vs library intent)
// / - Whether they export 一个 主 函数 (indicating program vs 库 intent)
/// - Public symbol counts (API surface area)
// / - Role recommendations based on module structure
// / - Role recommendations 基于 module structure
pub fn main() !void {
    // Use a fixed-size stack buffer for stdout to avoid heap allocation
    // Use 一个 fixed-size 栈 缓冲区 用于 stdout 到 avoid 堆 allocation
    var stdout_buffer: [768]u8 = undefined;
    var file_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &file_writer.interface;

    // Capture snapshots of module characteristics for analysis
    // 捕获 snapshots 的 module characteristics 用于 analysis
    const root_snapshot = roles.rootSnapshot();
    const library_snapshot = roles.librarySnapshot();
    // Retrieve role-based decision guidance
    const decisions = roles.decisions();

    try stdout.print("== Module vocabulary demo ==\n", .{});
    
    // Display root module role determination based on main export
    // 显示 root module role determination 基于 主 export
    try stdout.print(
        "root exports main? {s} → treat as {s}\n",
        .{
            if (root_snapshot.exports_main) "yes" else "no",
            root_snapshot.role,
        },
    );
    
    // Show the number of public declarations in the root module
    // Show 数字 的 public declarations 在 root module
    try stdout.print(
        "root public surface: {d} declarations\n",
        .{root_snapshot.public_symbol_count},
    );
    
    // Display library module metadata: name, version, and main export status
    // 显示 库 module metadata: name, version, 和 主 export 状态
    try stdout.print(
        "library '{s}' v{s} exports main? {s}\n",
        .{
            library_snapshot.name,
            library_snapshot.version,
            if (library_snapshot.exports_main) "yes" else "no",
        },
    );
    
    // Show the count of public modules or symbols in the library
    // Show count 的 public modules 或 symbols 在 库
    try stdout.print(
        "library modules listed: {d}\n",
        .{library_snapshot.public_symbol_count},
    );
    
    // Print architectural guidance for different module design goals
    // 打印 architectural guidance 用于 different module design goals
    try stdout.print("intent cheat sheet:\n", .{});
    for (decisions) |entry| {
        try stdout.print("  - {s} → {s}\n", .{ entry.goal, entry.recommendation });
    }

    // Flush buffered output to ensure all content is written
    // 刷新 缓冲 输出 到 确保 所有 content is written
    try stdout.flush();
}
