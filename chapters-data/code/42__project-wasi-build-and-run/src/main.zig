const std = @import("std");
const analysis = @import("analysis.zig");

pub fn main() !void {
    // Initialize general-purpose allocator for dynamic memory allocation
    // Initialize general-purpose allocator 用于 dynamic 内存 allocation
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Parse command-line arguments into an allocated slice
    // Parse command-line arguments into 一个 allocated 切片
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    // Check for optional --input flag to specify a file path
    // 检查 可选 --输入 flag 到 specify 一个 文件路径
    var input_path: ?[]const u8 = null;
    var i: usize = 1; // Skip program name at args[0]
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

    // Read input content from either file or stdin
    // 读取 输入 content 从 either 文件 或 stdin
    // Using labeled blocks to unify type across both branches
    // 使用 带标签的代码块 到 unify 类型 across both branches
    const content = if (input_path) |path| blk: {
        std.debug.print("analyzing: {s}\n", .{path});
        // Read entire file content with 10MB limit
        // 读取 entire 文件 content 使用 10MB limit
        break :blk try std.fs.cwd().readFileAlloc(allocator, path, 10 * 1024 * 1024);
    } else blk: {
        std.debug.print("analyzing: stdin\n", .{});
        // Construct File handle directly from stdin file descriptor
        // Construct 文件 处理 directly 从 stdin 文件 descriptor
        const stdin = std.fs.File{ .handle = std.posix.STDIN_FILENO };
        // Read all available stdin data with same 10MB limit
        // 读取 所有 available stdin 数据 使用 same 10MB limit
        break :blk try stdin.readToEndAlloc(allocator, 10 * 1024 * 1024);
    };
    defer allocator.free(content);

    // Delegate log analysis to the analysis module
    // Delegate log analysis 到 analysis module
    const stats = analysis.analyzeLog(content);
    
    // Print summary statistics to stderr (std.debug.print)
    // 打印 summary statistics 到 stderr (std.调试.打印)
    std.debug.print("results: INFO={d} WARN={d} ERROR={d}\n", .{
        stats.info_count,
        stats.warn_count,
        stats.error_count,
    });
}
