const std = @import("std");

pub fn main() void {
    // 进度可以绘制到 stderr；在此演示中禁用打印以获得确定性输出。
    const root = std.Progress.start(.{ .root_name = "build", .estimated_total_items = 3, .disable_printing = true });
    var compile = root.start("compile", 2);
    compile.completeOne();
    compile.completeOne();
    compile.end();

    var link = root.start("link", 1);
    link.completeOne();
    link.end();

    root.end();
}
