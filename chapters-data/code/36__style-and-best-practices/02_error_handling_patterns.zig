// ! Resource-safe error handling patterns with defer and errdefer.
// ! Resource-安全 错误处理 patterns 使用 defer 和 errdefer.

const std = @import("std");

// / Custom error set for data loading operations.
// / 自定义 错误集合 用于 数据 loading operations.
// / Keeping error sets small and explicit helps callers route failures precisely.
// / Keeping 错误 sets small 和 explicit helps callers route failures precisely.
pub const LoaderError = error{InvalidNumber};

// / Loads floating-point samples from a UTF-8 text file.
// / Loads floating-point 样本 从 一个 UTF-8 text 文件.
// / Each non-empty line is parsed as an f64.
// / 每个 non-空 line is parsed 作为 一个 f64.
// / Caller owns the returned slice and must free it with the same allocator.
// / Caller owns returned 切片 和 must 释放 it 使用 same allocator.
pub fn loadSamples(dir: std.fs.Dir, allocator: std.mem.Allocator, path: []const u8) ![]f64 {
    // Open the file; propagate any I/O errors to caller
    // Open 文件; propagate any I/O 错误 到 caller
    var file = try dir.openFile(path, .{});
    // Guarantee file handle is released when function exits, regardless of path taken
    // Guarantee 文件 处理 is released 当 函数 exits, regardless 的 路径 taken
    defer file.close();

    // Start with an empty list; we'll grow it as we parse lines
    // Start 使用 一个 空 list; we'll grow it 作为 we parse lines
    var list = std.ArrayListUnmanaged(f64){};
    // If any error occurs after this point, free the list's backing memory
    // 如果 any 错误 occurs after 此 point, 释放 list's backing 内存
    errdefer list.deinit(allocator);

    // Read entire file into memory; cap at 64KB for safety
    // 读取 entire 文件 into 内存; cap 在 64KB 用于 safety
    const contents = try file.readToEndAlloc(allocator, 1 << 16);
    // Free the temporary buffer once we've parsed it
    // 释放 temporary 缓冲区 once we've parsed it
    defer allocator.free(contents);

    // Split contents by newline; iterator yields one line at a time
    // Split contents 通过 newline; iterator yields 一个 line 在 一个 time
    var lines = std.mem.splitScalar(u8, contents, '\n');
    while (lines.next()) |line| {
        // Strip leading/trailing whitespace and carriage returns
        // Strip leading/trailing whitespace 和 carriage 返回
        const trimmed = std.mem.trim(u8, line, " \t\r");
        // Skip empty lines entirely
        // Skip 空 lines entirely
        if (trimmed.len == 0) continue;

        // Attempt to parse the line as a float; surface a domain-specific error on failure
        // 尝试 parse line 作为 一个 float; surface 一个 domain-specific 错误 在 failure
        const value = std.fmt.parseFloat(f64, trimmed) catch return LoaderError.InvalidNumber;
        // Append successfully parsed value to the list
        // Append successfully parsed 值 到 list
        try list.append(allocator, value);
    }

    // Transfer ownership of the backing array to the caller
    // Transfer ownership 的 backing 数组 到 caller
    return list.toOwnedSlice(allocator);
}

test "loadSamples returns parsed floats" {
    // Create a temporary directory that will be cleaned up automatically
    // 创建一个 temporary directory 该 will be cleaned up automatically
    var tmp_fs = std.testing.tmpDir(.{});
    defer tmp_fs.cleanup();

    // Write sample data to a test file
    // 写入 sample 数据 到 一个 test 文件
    const file_path = try tmp_fs.dir.createFile("samples.txt", .{});
    defer file_path.close();
    try file_path.writeAll("1.0\n2.5\n3.75\n");

    // Load and parse the samples; defer ensures cleanup even if assertions fail
    // Load 和 parse 样本; defer 确保 cleanup even 如果 assertions fail
    const samples = try loadSamples(tmp_fs.dir, std.testing.allocator, "samples.txt");
    defer std.testing.allocator.free(samples);

    // Verify we parsed exactly three values
    // Verify we parsed exactly 三个 值
    try std.testing.expectEqual(@as(usize, 3), samples.len);
    // Check each value is within acceptable floating-point tolerance
    // 检查 每个 值 is within acceptable floating-point tolerance
    try std.testing.expectApproxEqAbs(1.0, samples[0], 0.001);
    try std.testing.expectApproxEqAbs(2.5, samples[1], 0.001);
    try std.testing.expectApproxEqAbs(3.75, samples[2], 0.001);
}

test "loadSamples surfaces invalid numbers" {
    // Set up another temporary directory for error-path testing
    // Set up another temporary directory 用于 错误-路径 testing
    var tmp_fs = std.testing.tmpDir(.{});
    defer tmp_fs.cleanup();

    // Write non-numeric content to trigger parsing failure
    // 写入 non-numeric content 到 trigger 解析 failure
    const file_path = try tmp_fs.dir.createFile("bad.txt", .{});
    defer file_path.close();
    try file_path.writeAll("not-a-number\n");

    // Confirm that loadSamples returns the expected domain error
    // Confirm 该 loadSamples 返回 expected domain 错误
    try std.testing.expectError(LoaderError.InvalidNumber, loadSamples(tmp_fs.dir, std.testing.allocator, "bad.txt"));
}
