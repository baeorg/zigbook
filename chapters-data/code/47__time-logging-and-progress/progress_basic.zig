const std = @import("std");

pub fn main() void {
    // Progress can draw to stderr; disable printing in this demo for deterministic output.
    // Progress can draw 到 stderr; disable printing 在 此 demo 用于 deterministic 输出.
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
