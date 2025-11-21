const std = @import("std");

// 第4章 §1.2 - 演示如何使用每个错误的`catch`分支来塑造
// 恢复策略，同时不失去控制流的清晰性。

const ProbeError = error{ Disconnected, Timeout };

fn readProbe(id: usize) ProbeError!u8 {
    return switch (id) {
        0 => 42,
        1 => error.Timeout,
        2 => error.Disconnected,
        else => 88,
    };
}

pub fn main() !void {
    const ids = [_]usize{ 0, 1, 2, 3 };
    var total: u32 = 0;

    probe_loop: for (ids) |id| {
        const raw = readProbe(id) catch |err| handler: {
            switch (err) {
                error.Timeout => {
                    // 超时可以通过回退值软化，允许
                    // 循环继续执行"恢复并继续"路径。
                    std.debug.print("probe {} timed out; using fallback 200\n", .{id});
                    break :handler 200;
                },
                error.Disconnected => {
                    // 断开的传感器演示了章节中讨论的
                    // "完全跳过"恢复分支。
                    std.debug.print("probe {} disconnected; skipping sample\n", .{id});
                    continue :probe_loop;
                },
            }
        };

        total += raw;
        std.debug.print("probe {} -> {}\n", .{ id, raw });
    }

    std.debug.print("aggregate total = {}\n", .{total});
}
