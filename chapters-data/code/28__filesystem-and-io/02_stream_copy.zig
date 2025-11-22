const std = @import("std");

pub fn main() !void {
    // 初始化通用分配器用于动态内存分配
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // 创建用于流复制演示的工作目录
    const dir_name = "fs_stream_copy";
    try std.fs.cwd().makePath(dir_name);
    // 退出时清理目录，如果不存在则忽略错误
    defer std.fs.cwd().deleteTree(dir_name) catch {};

    // 为源文件构造平台无关的路径
    const source_path = try std.fs.path.join(allocator, &.{ dir_name, "source.txt" });
    defer allocator.free(source_path);

    // 创建具有截断和读取权限的源文件
    // 截断确保我们从空文件开始
    var source_file = try std.fs.cwd().createFile(source_path, .{ .truncate = true, .read = true });
    defer source_file.close();

    // 为源文件设置缓冲写入器
    // 缓冲区通过批量写入减少系统调用开销
    var source_writer_buffer: [128]u8 = undefined;
    var source_writer_state = source_file.writer(&source_writer_buffer);
    const source_writer = &source_writer_state.interface;

    // 向源文件写入示例数据
    try source_writer.print("alpha\n", .{});
    try source_writer.print("beta\n", .{});
    try source_writer.print("gamma\n", .{});
    // 刷新确保所有缓冲数据写入磁盘
    try source_writer.flush();

    // 将源文件光标倒回到开头以进行读取
    try source_file.seekTo(0);

    // 为目标文件构造平台无关的路径
    const dest_path = try std.fs.path.join(allocator, &.{ dir_name, "copy.txt" });
    defer allocator.free(dest_path);

    // 创建具有截断和读取权限的目标文件
    var dest_file = try std.fs.cwd().createFile(dest_path, .{ .truncate = true, .read = true });
    defer dest_file.close();

    // 为目标文件设置缓冲写入器
    var dest_writer_buffer: [64]u8 = undefined;
    var dest_writer_state = dest_file.writer(&dest_writer_buffer);
    const dest_writer = &dest_writer_state.interface;

    // 分配块缓冲区用于流复制操作
    var chunk: [128]u8 = undefined;
    var total_bytes: usize = 0;

    // 以块为单位从源流式传输数据到目标
    // 此方法对大文件内存高效
    while (true) {
        const read_len = try source_file.read(&chunk);
        // 读取长度为0表示EOF
        if (read_len == 0) break;
        // 将读取的确切字节数写入目标
        try dest_writer.writeAll(chunk[0..read_len]);
        total_bytes += read_len;
    }

    // 刷新目标写入器以确保所有数据持久化
    try dest_writer.flush();

    // 检索文件元数据以验证复制操作
    const info = try dest_file.stat();

    // 设置缓冲标准输出写入器用于显示结果
    var stdout_buffer: [256]u8 = undefined;
    var stdout_state = std.fs.File.stdout().writer(&stdout_buffer);
    const out = &stdout_state.interface;

    // 显示复制操作统计信息
    try out.print("copied {d} bytes\n", .{total_bytes});
    try out.print("destination size: {d}\n", .{info.size});

    // 将目标文件倒回以读取复制的内容
    try dest_file.seekTo(0);
    const copied = try dest_file.readToEndAlloc(allocator, 16 * 1024);
    defer allocator.free(copied);

    // 显示复制的文件内容以进行验证
    try out.print("--- copy.txt ---\n{s}", .{copied});
    // 刷新标准输出以确保所有输出显示
    try out.flush();
}
