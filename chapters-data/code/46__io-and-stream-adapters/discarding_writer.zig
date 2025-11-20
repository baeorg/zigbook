const std = @import("std");

// Demonstrate std.Io.Writer.Discarding to ignore outputs (useful in benchmarks)
// Demonstrate std.Io.Writer.Discarding 到 ignore outputs (useful 在 benchmarks)
pub fn main() !void {
    var buf: [32]u8 = undefined;
    var w: std.Io.Writer = .fixed(&buf);

    try w.print("Ephemeral output: {d}\n", .{999});

    // Discard content by consuming buffered bytes
    // Discard content 通过 consuming 缓冲 bytes
    _ = std.Io.Writer.consumeAll(&w);

    // Show buffer now empty
    // Show 缓冲区 now 空
    std.debug.print("Buffer after consumeAll length: {d}\n", .{w.buffered().len});
}
