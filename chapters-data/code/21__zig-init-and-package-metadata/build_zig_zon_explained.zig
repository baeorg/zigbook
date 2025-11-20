const std = @import("std");

pub fn main() !void {
    std.debug.print("== build.zig.zon 字段 ==\n", .{});
    std.debug.print("名称：项目的逻辑名称\n", .{});
    std.debug.print("版本：语义版本（major.minor.patch）\n", .{});
    std.debug.print("指纹：内容寻址哈希（防篡改）\n", .{});
    std.debug.print("minimum_zig_version：最低编译器版本\n", .{});
    std.debug.print("依赖项：嵌套的包引用\n", .{});
    std.debug.print("路径：本地源目录\n", .{});
}