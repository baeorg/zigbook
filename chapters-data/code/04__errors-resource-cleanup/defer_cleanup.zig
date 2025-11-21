const std = @import("std");

// 第4章 §2.1 - `defer`将清理与获取绑定，使读者能够在
// 一个词法作用域内看到资源的完整生命周期。

const JobError = error{CalibrateFailed};

const Resource = struct {
    name: []const u8,
    cleaned: bool = false,

    fn release(self: *Resource) void {
        if (!self.cleaned) {
            self.cleaned = true;
            std.debug.print("release {s}\n", .{self.name});
        }
    }
};

fn runJob(name: []const u8, should_fail: bool) JobError!void {
    std.debug.print("acquiring {s}\n", .{name});
    var res = Resource{ .name = name };
    // 在获取资源后立即放置`defer`，确保其释放操作
    // 在每个退出路径（无论是成功还是其他情况）都会触发。
    defer res.release();

    std.debug.print("working with {s}\n", .{name});
    if (should_fail) {
        std.debug.print("job {s} failed\n", .{name});
        return error.CalibrateFailed;
    }

    std.debug.print("job {s} succeeded\n", .{name});
}

pub fn main() !void {
    const jobs = [_]struct { name: []const u8, fail: bool }{
        .{ .name = "alpha", .fail = false },
        .{ .name = "beta", .fail = true },
    };

    for (jobs) |job| {
        std.debug.print("-- cycle {s} --\n", .{job.name});
        runJob(job.name, job.fail) catch |err| {
            // 即使作业失败，早期的`defer`也已经调度了
            // 保持资源平衡的清理操作。
            std.debug.print("{s} bubbled up {s}\n", .{ job.name, @errorName(err) });
        };
    }
}
