const std = @import("std");

pub fn main() !void {
    std.debug.print("== 模板比较 ==\n", .{});
    std.debug.print("最小：单文件，无模块分离\n", .{});
    std.debug.print("完整：根模块 + 可执行文件 + 测试\n", .{});
}