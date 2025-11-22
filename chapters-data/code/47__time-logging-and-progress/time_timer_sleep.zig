const std = @import("std");

pub fn main() !void {
    var t = try std.time.Timer.start();
    std.Thread.sleep(50 * std.time.ns_per_ms);
    const ns = t.read();
    // 确保我们至少睡了 50ms
    if (ns < 50 * std.time.ns_per_ms) return error.TimerResolutionTooLow;
    // 打印稳定的消息
    std.debug.print("Timer OK\n", .{});
}
