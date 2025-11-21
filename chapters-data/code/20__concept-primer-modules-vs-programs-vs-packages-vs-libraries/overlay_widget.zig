const std = @import("std");

//  Summary of a package registration as seen from the consumer invoking `--pkg-begin`.
//  从调用 `--pkg-begin` 的消费者视角看到的包注册摘要。
pub const PackageDetails = struct {
    package_name: []const u8,
    role: []const u8,
    optimize_mode: []const u8,
    target_os: []const u8,
};

//  Render a formatted summary that demonstrates how package registration exposes modules by name.
//  渲染格式化摘要，演示包注册如何按名称公开模块。
pub fn renderSummary(writer: anytype, details: PackageDetails) !void {
    try writer.print("registered package: {s}\n", .{details.package_name});
    try writer.print("role advertised: {s}\n", .{details.role});
    try writer.print("optimize mode: {s}\n", .{details.optimize_mode});
    try writer.print("target os: {s}\n", .{details.target_os});
    try writer.print(
        "resolved module namespace: overlay → pub decls: {d}\n",
        .{moduleDeclCount()},
    );
}

fn moduleDeclCount() usize {
    // Enumerate the declarations exported by this module to simulate API surface reporting.
    // 枚举此模块导出的声明以模拟API表面报告。
    return std.meta.declarations(@This()).len;
}
