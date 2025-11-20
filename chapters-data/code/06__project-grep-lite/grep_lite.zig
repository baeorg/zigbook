const std = @import("std");

// Chapter 6 – Grep-Lite: stream a file line by line and echo only the matches
// 章节 6 – Grep-Lite: stream 一个 文件 line 通过 line 和 echo only matches
// to stdout while errors become clear diagnostics on stderr.
// 到 stdout 当 错误 become clear diagnostics 在 stderr.

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

    // Buffered stdout using modern Writer API
    // 缓冲 stdout 使用 modern Writer API
    var out_buf: [8 * 1024]u8 = undefined;
    var file_writer = std.fs.File.writer(std.fs.File.stdout(), &out_buf);
    const stdout = &file_writer.interface;

    // Section 1.2: load the complete file eagerly while enforcing a guard so
    // 节 1.2: load complete 文件 eagerly 当 enforcing 一个 guard so
    // unexpected multi-megabyte inputs do not exhaust memory.
    // unexpected multi-megabyte inputs do 不 exhaust 内存.
    const max_bytes = 8 * 1024 * 1024;
    const contents = file.readToEndAlloc(allocator, max_bytes) catch |err| switch (err) {
        error.FileTooBig => {
            std.debug.print("error: file exceeds {} bytes limit\n", .{max_bytes});
            std.process.exit(1);
        },
        else => return err,
    };
    defer allocator.free(contents);

    // Section 2.1: split the buffer on newlines; each slice references the
    // 节 2.1: split 缓冲区 在 newlines; 每个 切片 references
    // original allocation so we incur zero extra copies.
    // 原始 allocation so we incur 零 extra copies.
    var lines = std.mem.splitScalar(u8, contents, '\n');
    var matches: usize = 0;

    while (lines.next()) |raw_line| {
        const line = trimNewline(raw_line);

        // Section 2: reuse `std.mem.indexOf` so we highlight exact matches
        // 节 2: reuse `std.mem.indexOf` so we highlight exact matches
        // without building temporary slices.
        if (std.mem.indexOf(u8, line, pattern) != null) {
            matches += 1;
            try stdout.print("{s}\n", .{line});
        }
    }

    if (matches == 0) {
        std.debug.print("no matches for '{s}' in {s}\n", .{ pattern, path });
    }

    // Flush buffered stdout and finalize file position
    // 刷新 缓冲 stdout 和 finalize 文件 position
    try file_writer.end();
}
