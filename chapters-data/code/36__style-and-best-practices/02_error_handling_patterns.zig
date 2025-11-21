// ! 使用defer和errdefer的资源安全错误处理模式。

const std = @import("std");

/// 用于数据加载操作的自定义错误集合。
/// 保持错误集合小而明确有助于调用者精确处理失败。
pub const LoaderError = error{InvalidNumber};

/// 从UTF-8文本文件加载浮点样本。
/// 每个非空行都被解析为f64。
/// 调用者拥有返回的切片，必须使用相同的分配器释放它。
pub fn loadSamples(dir: std.fs.Dir, allocator: std.mem.Allocator, path: []const u8) ![]f64 {
    // 打开文件；将任何I/O错误传播给调用者
    var file = try dir.openFile(path, .{});
    // 保证函数退出时释放文件句柄，无论采用哪种执行路径
    defer file.close();

    // 从空列表开始；解析行时会动态增长
    var list = std.ArrayListUnmanaged(f64){};
    // 如果在此之后发生任何错误，释放列表的后备内存
    errdefer list.deinit(allocator);

    // 将整个文件读入内存；安全起见限制为64KB
    const contents = try file.readToEndAlloc(allocator, 1 << 16);
    // 解析完成后释放临时缓冲区
    defer allocator.free(contents);

    // 按换行符分割内容；迭代器逐行产生
    var lines = std.mem.splitScalar(u8, contents, '\n');
    while (lines.next()) |line| {
        // 去除首尾空白和回车符
        const trimmed = std.mem.trim(u8, line, " \t\r");
        // 完全跳过空行
        if (trimmed.len == 0) continue;

        // 尝试将行解析为浮点数；失败时返回特定域错误
        const value = std.fmt.parseFloat(f64, trimmed) catch return LoaderError.InvalidNumber;
        // 将成功解析的值追加到列表
        try list.append(allocator, value);
    }

    // 将后备数组的所有权转移给调用者
    return list.toOwnedSlice(allocator);
}

test "loadSamples returns parsed floats" {
    // 创建一个将被自动清理的临时目录
    var tmp_fs = std.testing.tmpDir(.{});
    defer tmp_fs.cleanup();

    // 将示例数据写入测试文件
    const file_path = try tmp_fs.dir.createFile("samples.txt", .{});
    defer file_path.close();
    try file_path.writeAll("1.0\n2.5\n3.75\n");

    // 加载并解析样本；defer确保即使断言失败也会清理
    const samples = try loadSamples(tmp_fs.dir, std.testing.allocator, "samples.txt");
    defer std.testing.allocator.free(samples);

    // 验证我们解析了恰好三个值
    try std.testing.expectEqual(@as(usize, 3), samples.len);
    // 检查每个值都在可接受的浮点容差范围内
    try std.testing.expectApproxEqAbs(1.0, samples[0], 0.001);
    try std.testing.expectApproxEqAbs(2.5, samples[1], 0.001);
    try std.testing.expectApproxEqAbs(3.75, samples[2], 0.001);
}

test "loadSamples surfaces invalid numbers" {
    // 为错误路径测试设置另一个临时目录
    var tmp_fs = std.testing.tmpDir(.{});
    defer tmp_fs.cleanup();

    // 写入非数字内容以触发解析失败
    const file_path = try tmp_fs.dir.createFile("bad.txt", .{});
    defer file_path.close();
    try file_path.writeAll("not-a-number\n");

    // 确认loadSamples返回预期的域错误
    try std.testing.expectError(LoaderError.InvalidNumber, loadSamples(tmp_fs.dir, std.testing.allocator, "bad.txt"));
}
