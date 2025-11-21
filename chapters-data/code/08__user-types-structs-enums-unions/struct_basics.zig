const std = @import("std");

// 第8章 — 结构体基础：字段、方法、默认值、命名空间
//
// 演示如何使用字段和方法定义结构体，包括
// 默认字段值。同时展示方法的命名空间与自由函数的区别。
//
// Usage: 
//    zig run struct_basics.zig

const Point = struct {
    x: i32,
    y: i32 = 0, // default value

    pub fn len(self: Point) f64 {
        const dx = @as(f64, @floatFromInt(self.x));
        const dy = @as(f64, @floatFromInt(self.y));
        return std.math.sqrt(dx * dx + dy * dy);
    }

    pub fn translate(self: *Point, dx: i32, dy: i32) void {
        self.x += dx;
        self.y += dy;
    }
};

// 命名空间：文件作用域的自由函数与方法
fn distanceFromOrigin(p: Point) f64 {
    return p.len();
}

pub fn main() !void {
    var p = Point{ .x = 3 }; // y uses default 0
    std.debug.print("p=({d},{d}) len={d:.3}\n", .{ p.x, p.y, p.len() });

    p.translate(-3, 4);
    std.debug.print("p=({d},{d}) len={d:.3}\n", .{ p.x, p.y, distanceFromOrigin(p) });
}
