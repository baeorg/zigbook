const std = @import("std");
const builtin = @import("builtin");

pub fn main() !void {
    // 使用便利辅助函数向 stderr 发送一个简短的通知。
    std.debug.print("[stderr] staged diagnostics\n", .{});

    // 明确锁定 stderr 以处理多行消息。
    {
        const writer = std.debug.lockStderrWriter(&.{});
        defer std.debug.unlockStderrWriter();
        writer.writeAll("[stderr] stack capture incoming\n") catch {};
    }

    var stdout_buffer: [256]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const out = &stdout_writer.interface;

    // 捕获一个修剪过的堆栈跟踪，而不打印原始地址。
    var frame_storage: [8]usize = undefined;
    var trace = std.builtin.StackTrace{
        .index = 0,
        .instruction_addresses = frame_storage[0..],
    };
    std.debug.captureStackTrace(null, &trace);
    try out.print("frames captured -> {d}\n", .{trace.index});

    // 使用参与安全模式的调试断言来守护一个哨兵。
    const marker = "panic probe";
    std.debug.assert(marker.len == 11);

    var buffer = [_]u8{ 0x41, 0x42, 0x43, 0x44 };
    std.debug.assertReadable(buffer[0..]);
    std.debug.assertAligned(&buffer, .@"1");

    // 报告从 std.debug 收集的构建配置事实。
    try out.print(
        "runtime_safety -> {s}\n",
        .{if (std.debug.runtime_safety) "enabled" else "disabled"},
    );
    try out.print(
        "optimize_mode -> {s}\n",
        .{@tagName(builtin.mode)},
    );

    // 针对固定缓冲区显示手动格式化，在 stderr 被锁定时很有用。
    var scratch: [96]u8 = undefined;
    var stream = std.io.fixedBufferStream(&scratch);
    try stream.writer().print("captured slice -> {s}\n", .{marker});
    try out.print("{s}", .{stream.getWritten()});
    try out.flush();
}
