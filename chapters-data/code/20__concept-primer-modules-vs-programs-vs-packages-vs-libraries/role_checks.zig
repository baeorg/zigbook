const root = @import("root");
const manifest_pkg = @import("pkg/manifest.zig");

/// 快照，描述模块或库表面的分类。
pub const ModuleSnapshot = struct {
    name: []const u8,
    version: []const u8,
    exports_main: bool,
    role: []const u8,
    public_symbol_count: usize,
};

/// 开发目标与推荐Zig单元之间的映射。
pub const IntentDecision = struct {
    goal: []const u8,
    recommendation: []const u8,
};

/// 内省根模块以决定它是否表现得像程序或纯模块。
pub fn rootSnapshot() ModuleSnapshot {
    const exports_main = @hasDecl(root, "main");
    return .{
        .name = "root",
        .version = "n/a",
        .exports_main = exports_main,
        .role = if (exports_main) "program" else "module",
        .public_symbol_count = root.PublicSurface.len,
    };
}

/// 使用根模块提供的清单来描述为重用注册的库表面。
pub fn librarySnapshot() ModuleSnapshot {
    const manifest = root.libraryManifest();
    return .{
        .name = manifest.name,
        .version = manifest.version,
        .exports_main = manifest.exports_main,
        .role = if (manifest.exports_main) "program" else "library",
        .public_symbol_count = manifest.modules.len,
    };
}

/// 策展的意图到单元推荐，支持演示打印的备忘单。
pub fn decisions() []const IntentDecision {
    return &[_]IntentDecision{
        .{ .goal = "ship a CLI entry point", .recommendation = "program" },
        .{ .goal = "publish reusable code", .recommendation = "package + library" },
        .{ .goal = "share type definitions inside a workspace", .recommendation = "module" },
    };
}
