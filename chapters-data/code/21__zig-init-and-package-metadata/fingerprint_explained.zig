const std = @import("std");

pub fn main() !void {
    std.debug.print("== 指纹安全 ==\n", .{});
    std.debug.print("哈希覆盖：所有源文件 + build.zig.zon\n", .{});
    std.debug.print("防篡改：任何更改都会更改指纹\n", .{});
    std.debug.print("全局唯一：相同内容 = 相同指纹\n", .{});
}