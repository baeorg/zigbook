const std = @import("std");

pub fn main() !void {
    std.debug.print("== 依赖项类型 ==\n", .{});
    std.debug.print("远程：从URL + 哈希获取\n", .{});
    std.debug.print("本地：从文件系统路径导入\n", .{});
    std.debug.print("延迟：按需获取（用于大型/可选依赖项）\n", .{});
}