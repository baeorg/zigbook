const std = @import("std");

// 第6章 - Grep-Lite：逐行流式处理文件并仅回显匹配项到stdout，
// 同时将错误转换为stderr上的清晰诊断信息。

const CliError = error{MissingArgs};

fn printUsage() void {
    std.debug.print("usage: grep-lite <pattern> <path>\n", .{});
}

fn trimNewline(line: []const u8) []const u8 {
    if (line.len > 0 and line[line.len - 1] == '\r') {
        return line[0 .. line.len - 1];
    }
    return line;
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len == 1 or (args.len == 2 and std.mem.eql(u8, args[1], "--help"))) {
        printUsage();
        return;
    }

    if (args.len != 3) {
        std.debug.print("error: expected a pattern and a path\n", .{});
        printUsage();
        std.process.exit(1);
    }

    const pattern = args[1];
    const path = args[2];

    var file = std.fs.cwd().openFile(path, .{ .mode = .read_only }) catch {
        std.debug.print("error: unable to open '{s}'\n", .{path});
        std.process.exit(1);
    };
    defer file.close();

    // 使用现代Writer API的缓冲stdout
    var out_buf: [8 * 1024]u8 = undefined;
    var file_writer = std.fs.File.writer(std.fs.File.stdout(), &out_buf);
    const stdout = &file_writer.interface;

    // 第1.2节：积极加载完整文件，同时强制执行保护，
    // 防止意外的多兆字节输入耗尽内存。
    const max_bytes = 8 * 1024 * 1024;
    const contents = file.readToEndAlloc(allocator, max_bytes) catch |err| switch (err) {
        error.FileTooBig => {
            std.debug.print("error: file exceeds {} bytes limit\n", .{max_bytes});
            std.process.exit(1);
        },
        else => return err,
    };
    defer allocator.free(contents);

    // 第2.1节：在换行符处分割缓冲区；每个切片引用
    // 原始分配，因此不会产生额外的副本。
    var lines = std.mem.splitScalar(u8, contents, '\n');
    var matches: usize = 0;

    while (lines.next()) |raw_line| {
        const line = trimNewline(raw_line);

        // 第2节：重用`std.mem.indexOf`以精确高亮匹配项，
        // 而无需构建临时切片。
        if (std.mem.indexOf(u8, line, pattern) != null) {
            matches += 1;
            try stdout.print("{s}\n", .{line});
        }
    }

    if (matches == 0) {
        std.debug.print("no matches for '{s}' in {s}\n", .{ pattern, path });
    }

    // 刷新缓冲stdout并定位文件位置
    try file_writer.end();
}
