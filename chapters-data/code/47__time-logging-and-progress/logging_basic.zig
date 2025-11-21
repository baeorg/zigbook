const std = @import("std");

// Configure logging for this program
// 为此程序配置日志记录
pub const std_options: std.Options = .{
    .log_level = .info, // hide debug
    .logFn = std.log.defaultLog,
};

pub fn main() void {
    std.log.debug("debug hidden", .{});
    std.log.info("starting", .{});
    std.log.warn("high temperature", .{});

    const app = std.log.scoped(.app);
    app.info("running", .{});
}
