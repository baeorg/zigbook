const std = @import("std");

// / Helper function to create a directory path from multiple path components
// / 从多个路径组件创建目录路径的辅助函数
// / Joins path segments using platform-appropriate separators and creates the full path
// / 使用平台适当的分隔符连接路径段并创建完整路径
fn ensurePath(allocator: std.mem.Allocator, parts: []const []const u8) !void {
    // Join path components into a single platform-neutral path string
    // 将路径组件连接成单个平台无关的路径字符串
    const joined = try std.fs.path.join(allocator, parts);
    defer allocator.free(joined);
    // Create the directory path, including any missing parent directories
    // 创建目录路径，包括任何缺失的父目录
    try std.fs.cwd().makePath(joined);
}

// / Helper function to create a file and write contents to it
// / 创建文件并写入内容的辅助函数
// / Constructs the file path from components, creates the file, and writes data using buffered I/O
// / 从组件构造文件路径，创建文件，并使用缓冲 I/O 写入数据
fn writeFile(allocator: std.mem.Allocator, parts: []const []const u8, contents: []const u8) !void {
    // Join path components into a single platform-neutral path string
    // 将路径组件连接成单个平台无关的路径字符串
    const joined = try std.fs.path.join(allocator, parts);
    defer allocator.free(joined);
    // Create a new file with truncate option to start with an empty file
    // 使用截断选项创建新文件，从空文件开始
    var file = try std.fs.cwd().createFile(joined, .{ .truncate = true });
    defer file.close();
    // Set up a buffered writer to reduce syscall overhead
    // 设置缓冲写入器以减少系统调用开销
    var buffer: [128]u8 = undefined;
    var state = file.writer(&buffer);
    const writer = &state.interface;
    // Write the contents to the file and ensure all data is persisted
    try writer.writeAll(contents);
    try writer.flush();
}

pub fn main() !void {
    // Initialize a general-purpose allocator for dynamic memory allocation
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create a temporary directory structure for the directory walk demonstration
    const root = "fs_walk_listing";
    try std.fs.cwd().makePath(root);
    // Clean up the directory tree on exit, ignoring errors if it doesn't exist
    defer std.fs.cwd().deleteTree(root) catch {};

    // Create a multi-level directory structure with nested subdirectories
    try ensurePath(allocator, &.{ root, "logs", "app" });
    try ensurePath(allocator, &.{ root, "logs", "jobs" });
    try ensurePath(allocator, &.{ root, "notes" });

    // Populate the directory structure with sample files
    try writeFile(allocator, &.{ root, "logs", "app", "today.log" }, "ok 200\n");
    try writeFile(allocator, &.{ root, "logs", "app", "errors.log" }, "warn 429\n");
    try writeFile(allocator, &.{ root, "logs", "jobs", "batch.log" }, "started\n");
    try writeFile(allocator, &.{ root, "notes", "todo.txt" }, "rotate logs\n");

    // Open the root directory with iteration capabilities for traversal
    var root_dir = try std.fs.cwd().openDir(root, .{ .iterate = true });
    defer root_dir.close();

    // Create a directory walker to recursively traverse the directory tree
    var walker = try root_dir.walk(allocator);
    defer walker.deinit();

    // Set up a buffered stdout writer for efficient console output
    var stdout_buffer: [512]u8 = undefined;
    var stdout_state = std.fs.File.stdout().writer(&stdout_buffer);
    const out = &stdout_state.interface;

    // Initialize counters to track directory contents
    var total_dirs: usize = 0;
    var total_files: usize = 0;
    var log_files: usize = 0;

    // Walk the directory tree recursively, processing each entry
    while (try walker.next()) |entry| {
        // Extract the null-terminated path from the entry
        const path = std.mem.sliceTo(entry.path, 0);
        // Process entry based on its type (directory, file, etc.)
        switch (entry.kind) {
            .directory => {
                total_dirs += 1;
                try out.print("DIR  {s}\n", .{path});
            },
            .file => {
                total_files += 1;
                // Retrieve file metadata to display size information
                const info = try entry.dir.statFile(entry.basename);
                // Check if the file has a .log extension
                const is_log = std.mem.endsWith(u8, path, ".log");
                if (is_log) log_files += 1;
                // Display file path, size, and mark log files with a tag
                try out.print("FILE {s} ({d} bytes){s}\n", .{
                    path,
                    info.size,
                    if (is_log) " [log]" else "",
                });
            },
            // Ignore other entry types (symlinks, etc.)
            else => {},
        }
    }

    // Display summary statistics of the directory walk
    try out.print("--- summary ---\n", .{});
    try out.print("directories: {d}\n", .{total_dirs});
    try out.print("files: {d}\n", .{total_files});
    try out.print("log files: {d}\n", .{log_files});
    // Flush stdout to ensure all output is displayed
    try out.flush();
}
