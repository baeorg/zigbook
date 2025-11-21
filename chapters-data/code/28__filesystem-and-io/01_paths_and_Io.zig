const std = @import("std");

pub fn main() !void {
    // 初始化通用分配器用于动态内存分配
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // 创建用于文件系统操作的工作目录
    const dir_name = "fs_walkthrough";
    try std.fs.cwd().makePath(dir_name);
    // 退出时清理目录，如果不存在则忽略错误
    defer std.fs.cwd().deleteTree(dir_name) catch {};

    // 通过连接目录和文件名构造平台无关的路径
    const file_path = try std.fs.path.join(allocator, &.{ dir_name, "metrics.log" });
    defer allocator.free(file_path);

    // 创建具有截断和读取权限的新文件
    // 截断确保我们从空文件开始
    var file = try std.fs.cwd().createFile(file_path, .{ .truncate = true, .read = true });
    defer file.close();

    // 为高效文件I/O设置缓冲写入器
    // 缓冲区通过批量写入减少系统调用开销
    var file_writer_buffer: [256]u8 = undefined;
    var file_writer_state = file.writer(&file_writer_buffer);
    const file_writer = &file_writer_state.interface;

    // 通过缓冲写入器将CSV数据写入文件
    try file_writer.print("timestamp,value\n", .{});
    try file_writer.print("2025-11-05T09:00Z,42\n", .{});
    try file_writer.print("2025-11-05T09:05Z,47\n", .{});
    // 刷新确保所有缓冲数据写入磁盘
    try file_writer.flush();

    // 将相对路径解析为绝对文件系统路径
    const absolute_path = try std.fs.cwd().realpathAlloc(allocator, file_path);
    defer allocator.free(absolute_path);

    // 将文件光标倒回到开头以重新读取我们写入的内容
    try file.seekTo(0);
    // 将整个文件内容读取到分配的内存中（最大16 KiB）
    const contents = try file.readToEndAlloc(allocator, 16 * 1024);
    defer allocator.free(contents);

    // 从路径中提取文件名和目录组件
    const file_name = std.fs.path.basename(file_path);
    const dir_part = std.fs.path.dirname(file_path) orelse ".";

    // 根据Zig 0.15.2最佳实践设置缓冲stdout写入器
    // 缓冲stdout可提高多次打印调用的性能
    var stdout_buffer: [512]u8 = undefined;
    var stdout_state = std.fs.File.stdout().writer(&stdout_buffer);
    const out = &stdout_state.interface;

    // 显示文件元数据和内容到stdout
    try out.print("file name: {s}\n", .{file_name});
    try out.print("directory: {s}\n", .{dir_part});
    try out.print("absolute path: {s}\n", .{absolute_path});
    try out.print("--- file contents ---\n{s}", .{contents});
    // 刷新stdout缓冲区以确保显示所有输出
    try out.flush();
}
