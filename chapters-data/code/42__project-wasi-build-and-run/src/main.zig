const std = @import("std");
const analysis = @import("analysis.zig");

pub fn main() !void {
    // 初始化通用分配器用于动态内存分配
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // 将命令行参数解析为分配的切片
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    // 检查可选的--input标志以指定文件路径
    var input_path: ?[]const u8 = null;
    var i: usize = 1; // 跳过args[0]处的程序名
    while (i < args.len) : (i += 1) {
        if (std.mem.eql(u8, args[i], "--input")) {
            i += 1;
            if (i < args.len) {
                input_path = args[i];
            } else {
                std.debug.print("ERROR: --input requires a file path\n", .{});
                return error.MissingArgument;
            }
        }
    }

    // 从文件或stdin读取输入内容
    // 使用带标签的代码块在两个分支中统一类型
    const content = if (input_path) |path| blk: {
        std.debug.print("analyzing: {s}\n", .{path});
        // 读取整个文件内容，限制为10MB
        break :blk try std.fs.cwd().readFileAlloc(allocator, path, 10 * 1024 * 1024);
    } else blk: {
        std.debug.print("analyzing: stdin\n", .{});
        // 直接从stdin文件描述符构造文件句柄
        const stdin = std.fs.File{ .handle = std.posix.STDIN_FILENO };
        // 读取所有可用的stdin数据，限制为10MB
        break :blk try stdin.readToEndAlloc(allocator, 10 * 1024 * 1024);
    };
    defer allocator.free(content);

    // 将日志分析委托给analysis模块
    const stats = analysis.analyzeLog(content);

    // 打印摘要统计信息到stderr（std.debug.print）
    std.debug.print("results: INFO={d} WARN={d} ERROR={d}\n", .{
        stats.info_count,
        stats.warn_count,
        stats.error_count,
    });
}
