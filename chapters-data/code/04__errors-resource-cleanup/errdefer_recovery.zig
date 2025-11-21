const std = @import("std");

// 第4章 §2.2 - 分阶段设置使用`errdefer`保护，因此
// 部分初始化的通道在失败时会自动回滚。

const SetupError = error{ OpenFailed, RegisterFailed };

const Channel = struct {
    name: []const u8,
    opened: bool = false,
    registered: bool = false,

    fn teardown(self: *Channel) void {
        if (self.registered) {
            std.debug.print("deregister \"{s}\"\n", .{self.name});
            self.registered = false;
        }
        if (self.opened) {
            std.debug.print("closing \"{s}\"\n", .{self.name});
            self.opened = false;
        }
    }
};

fn setupChannel(name: []const u8, fail_on_register: bool) SetupError!Channel {
    std.debug.print("opening \"{s}\"\n", .{name});

    if (name.len == 0) {
        return error.OpenFailed;
    }

    var channel = Channel{ .name = name, .opened = true };
    errdefer {
        // 如果后续任何步骤失败，我们执行回滚块，镜像
        // "errdefer回滚部分初始化"章节。
        std.debug.print("rollback \"{s}\"\n", .{name});
        channel.teardown();
    }

    std.debug.print("registering \"{s}\"\n", .{name});
    if (fail_on_register) {
        return error.RegisterFailed;
    }

    channel.registered = true;
    return channel;
}

pub fn main() !void {
    std.debug.print("-- success path --\n", .{});
    var primary = try setupChannel("primary", false);
    defer primary.teardown();

    std.debug.print("-- register failure --\n", .{});
    _ = setupChannel("backup", true) catch |err| {
        std.debug.print("setup failed with {s}\n", .{@errorName(err)});
    };

    std.debug.print("-- open failure --\n", .{});
    _ = setupChannel("", false) catch |err| {
        std.debug.print("setup failed with {s}\n", .{@errorName(err)});
    };
}
