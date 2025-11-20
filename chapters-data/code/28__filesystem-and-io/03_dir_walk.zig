const std = @import("std");

// / Helper function to create a directory path from multiple path components
// / Helper 函数 到 创建一个 directory 路径 从 multiple 路径 components
// / Joins path segments using platform-appropriate separators and creates the full path
// / Joins 路径 segments 使用 platform-appropriate separators 和 creates 满 路径
fn ensurePath(allocator: std.mem.Allocator, parts: []const []const u8) !void {
    // Join path components into a single platform-neutral path string
    // Join 路径 components into 一个 single platform-neutral 路径 string
    const joined = try std.fs.path.join(allocator, parts);
    defer allocator.free(joined);
    // Create the directory path, including any missing parent directories
    // 创建 directory 路径, including any 缺失 parent directories
    try std.fs.cwd().makePath(joined);
}

// / Helper function to create a file and write contents to it
// / Helper 函数 到 创建一个 文件 和 写入 contents 到 it
// / Constructs the file path from components, creates the file, and writes data using buffered I/O
// / Constructs 文件路径 从 components, creates 文件, 和 writes 数据 使用 缓冲 I/O
fn writeFile(allocator: std.mem.Allocator, parts: []const []const u8, contents: []const u8) !void {
    // Join path components into a single platform-neutral path string
    // Join 路径 components into 一个 single platform-neutral 路径 string
    const joined = try std.fs.path.join(allocator, parts);
    defer allocator.free(joined);
    // Create a new file with truncate option to start with an empty file
    // 创建一个 新 文件 使用 truncate option 到 start 使用 一个 空 文件
    var file = try std.fs.cwd().createFile(joined, .{ .truncate = true });
    defer file.close();
    // Set up a buffered writer to reduce syscall overhead
    // Set up 一个 缓冲写入器 到 reduce syscall overhead
    var buffer: [128]u8 = undefined;
    var state = file.writer(&buffer);
    const writer = &state.interface;
    // Write the contents to the file and ensure all data is persisted
    // 写入 contents 到 文件 和 确保 所有 数据 is persisted
    try writer.writeAll(contents);
    try writer.flush();
}

pub fn main() !void {
    // Initialize a general-purpose allocator for dynamic memory allocation
    // Initialize 一个 general-purpose allocator 用于 dynamic 内存 allocation
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create a temporary directory structure for the directory walk demonstration
    // 创建一个 temporary directory structure 用于 directory walk demonstration
    const root = "fs_walk_listing";
    try std.fs.cwd().makePath(root);
    // Clean up the directory tree on exit, ignoring errors if it doesn't exist
    // Clean up directory tree 在 退出, ignoring 错误 如果 it doesn't exist
    defer std.fs.cwd().deleteTree(root) catch {};

    // Create a multi-level directory structure with nested subdirectories
    // 创建一个 multi-level directory structure 使用 nested subdirectories
    try ensurePath(allocator, &.{ root, "logs", "app" });
    try ensurePath(allocator, &.{ root, "logs", "jobs" });
    try ensurePath(allocator, &.{ root, "notes" });

    // Populate the directory structure with sample files
    // Populate directory structure 使用 sample 文件
    try writeFile(allocator, &.{ root, "logs", "app", "today.log" }, "ok 200\n");
    try writeFile(allocator, &.{ root, "logs", "app", "errors.log" }, "warn 429\n");
    try writeFile(allocator, &.{ root, "logs", "jobs", "batch.log" }, "started\n");
    try writeFile(allocator, &.{ root, "notes", "todo.txt" }, "rotate logs\n");

    // Open the root directory with iteration capabilities for traversal
    // Open root directory 使用 iteration capabilities 用于 traversal
    var root_dir = try std.fs.cwd().openDir(root, .{ .iterate = true });
    defer root_dir.close();

    // Create a directory walker to recursively traverse the directory tree
    // 创建一个 directory walker 到 recursively traverse directory tree
    var walker = try root_dir.walk(allocator);
    defer walker.deinit();

    // Set up a buffered stdout writer for efficient console output
    // Set up 一个 缓冲 stdout writer 用于 efficient console 输出
    var stdout_buffer: [512]u8 = undefined;
    var stdout_state = std.fs.File.stdout().writer(&stdout_buffer);
    const out = &stdout_state.interface;

    // Initialize counters to track directory contents
    // Initialize counters 到 track directory contents
    var total_dirs: usize = 0;
    var total_files: usize = 0;
    var log_files: usize = 0;

    // Walk the directory tree recursively, processing each entry
    // Walk directory tree recursively, processing 每个 entry
    while (try walker.next()) |entry| {
        // Extract the null-terminated path from the entry
        // Extract 空-terminated 路径 从 entry
        const path = std.mem.sliceTo(entry.path, 0);
        // Process entry based on its type (directory, file, etc.)
        // Process entry 基于 its 类型 (directory, 文件, 等.)
        switch (entry.kind) {
            .directory => {
                total_dirs += 1;
                try out.print("DIR  {s}\n", .{path});
            },
            .file => {
                total_files += 1;
                // Retrieve file metadata to display size information
                // Retrieve 文件 metadata 到 显示 size 信息
                const info = try entry.dir.statFile(entry.basename);
                // Check if the file has a .log extension
                // 检查 如果 文件 has 一个 .log extension
                const is_log = std.mem.endsWith(u8, path, ".log");
                if (is_log) log_files += 1;
                // Display file path, size, and mark log files with a tag
                // 显示 文件路径, size, 和 mark log 文件 使用 一个 tag
                try out.print("FILE {s} ({d} bytes){s}\n", .{
                    path,
                    info.size,
                    if (is_log) " [log]" else "",
                });
            },
            // Ignore other entry types (symlinks, etc.)
            // Ignore other entry 类型 (symlinks, 等.)
            else => {},
        }
    }

    // Display summary statistics of the directory walk
    // 显示 summary statistics 的 directory walk
    try out.print("--- summary ---\n", .{});
    try out.print("directories: {d}\n", .{total_dirs});
    try out.print("files: {d}\n", .{total_files});
    try out.print("log files: {d}\n", .{log_files});
    // Flush stdout to ensure all output is displayed
    // 刷新 stdout 到 确保 所有 输出 is displayed
    try out.flush();
}
