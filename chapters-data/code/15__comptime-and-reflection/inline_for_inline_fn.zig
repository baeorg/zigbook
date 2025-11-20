const std = @import("std");

fn stdout() *std.Io.Writer {
    const g = struct {
        var buf: [1024]u8 = undefined;
        var w = std.fs.File.stdout().writer(&buf);
    };
    return &g.w.interface;
}

// An inline function; the compiler is allowed to inline automatically too,
// 一个 inline 函数; compiler is allowed 到 inline automatically too,
// but `inline` forces it (use sparingly—can increase code size).
// but `inline` forces it (use sparingly—can increase 代码 size).
inline fn mulAdd(a: u64, b: u64, c: u64) u64 {
    return a * b + c;
}

pub fn main() !void {
    const out = stdout();

    // inline for: unroll a small loop at compile time
    // inline 用于: unroll 一个 small loop 在 编译时
    var acc: u64 = 0;
    inline for (.{ 1, 2, 3, 4 }) |v| {
        acc = mulAdd(acc, 2, v); // (((0*2+1)*2+2)*2+3)*2+4
    }
    try out.print("acc={}\n", .{acc});

    // demonstrate that `inline` is not magic; it's a trade-off
    // demonstrate 该 `inline` is 不 magic; it's 一个 trade-off
    // prefer profiling for hot paths before forcing inline.
    // prefer profiling 用于 hot 路径 before forcing inline.
    try out.flush();
}
