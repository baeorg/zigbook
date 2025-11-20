const std = @import("std");

// Chapter 8 — Struct basics: fields, methods, defaults, namespacing
// 章节 8 — Struct basics: fields, methods, defaults, namespacing
// 
// Demonstrates defining a struct with fields and methods, including
// 演示 defining 一个 struct 使用 fields 和 methods, including
// default field values. Also shows namespacing of methods vs free functions.
// 默认 field 值. Also shows namespacing 的 methods vs 释放 函数.
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

// Namespacing: free function in file scope vs method
// Namespacing: 释放 函数 在 文件 scope vs method
fn distanceFromOrigin(p: Point) f64 {
    return p.len();
}

pub fn main() !void {
    var p = Point{ .x = 3 }; // y uses default 0
    std.debug.print("p=({d},{d}) len={d:.3}\n", .{ p.x, p.y, p.len() });

    p.translate(-3, 4);
    std.debug.print("p=({d},{d}) len={d:.3}\n", .{ p.x, p.y, distanceFromOrigin(p) });
}
