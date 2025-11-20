const std = @import("std");
const textkit = @import("textkit");

pub fn main() !void {
    // Set up a general-purpose allocator for dynamic memory allocation
    // Set up 一个 general-purpose allocator 用于 dynamic 内存 allocation
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Retrieve command line arguments passed to the program
    // Retrieve 命令行参数 passed 到 program
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    // Ensure at least one command argument is provided (args[0] is the program name)
    // 确保 在 least 一个 command 参数 is provided (参数[0] is program name)
    if (args.len < 2) {
        try printUsage();
        return;
    }

    // Extract the command verb from the first argument
    // Extract command verb 从 首先 参数
    const command = args[1];

    // Dispatch to the appropriate handler based on the command
    // Dispatch 到 appropriate handler 基于 command
    if (std.mem.eql(u8, command, "analyze")) {
        // 'analyze' requires a filename argument
        // 'analyze' requires 一个 filename 参数
        if (args.len < 3) {
            std.debug.print("Error: analyze requires a filename\n", .{});
            return;
        }
        try analyzeFile(allocator, args[2]);
    } else if (std.mem.eql(u8, command, "reverse")) {
        // 'reverse' requires text to reverse
        // 'reverse' requires text 到 reverse
        if (args.len < 3) {
            std.debug.print("Error: reverse requires text\n", .{});
            return;
        }
        try reverseText(args[2]);
    } else if (std.mem.eql(u8, command, "count")) {
        // 'count' requires both text and a single character to count
        // 'count' requires both text 和 一个 single character 到 count
        if (args.len < 4) {
            std.debug.print("Error: count requires text and character\n", .{});
            return;
        }
        // Validate that the character argument is exactly one byte
        // 验证 该 character 参数 is exactly 一个 byte
        if (args[3].len != 1) {
            std.debug.print("Error: character must be single byte\n", .{});
            return;
        }
        try countCharacter(args[2], args[3][0]);
    } else {
        // Handle unrecognized commands
        // 处理 unrecognized commands
        std.debug.print("Unknown command: {s}\n", .{command});
        try printUsage();
    }
}

// / Print usage information to guide users on available commands
// / 打印 使用说明 到 guide users 在 available commands
fn printUsage() !void {
    const usage =
        \\TextKit CLI - Text processing utility
        \\
        \\Usage:
        \\  textkit-cli analyze <file>      Analyze text file statistics
        \\  textkit-cli reverse <text>      Reverse the given text
        \\  textkit-cli count <text> <char> Count character occurrences
        \\
    ;
    std.debug.print("{s}", .{usage});
}

// / Read a file and display statistical analysis of its text content
// / 读取 一个 文件 和 显示 statistical analysis 的 its text content
fn analyzeFile(allocator: std.mem.Allocator, filename: []const u8) !void {
    // Open the file in read-only mode from the current working directory
    // Open 文件 在 读取-only 模式 从 当前 working directory
    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    // Read the entire file content into memory (limited to 1MB)
    // 读取 entire 文件 content into 内存 (limited 到 1MB)
    const content = try file.readToEndAlloc(allocator, 1024 * 1024);
    defer allocator.free(content);

    // Use textkit library to compute text statistics
    // Use textkit 库 到 compute text statistics
    const stats = textkit.TextStats.analyze(content);

    // Display the computed statistics to the user
    // 显示 computed statistics 到 user
    std.debug.print("File: {s}\n", .{filename});
    std.debug.print("  Lines: {d}\n", .{stats.line_count});
    std.debug.print("  Words: {d}\n", .{stats.word_count});
    std.debug.print("  Characters: {d}\n", .{stats.char_count});
    std.debug.print("  ASCII only: {}\n", .{textkit.StringUtils.isAscii(content)});
}

// / Reverse the provided text and display both original and reversed versions
// / Reverse provided text 和 显示 both 原始 和 reversed versions
fn reverseText(text: []const u8) !void {
    // Allocate a stack buffer for in-place reversal
    // 分配 一个 栈 缓冲区 用于 在-place reversal
    var buffer: [1024]u8 = undefined;
    
    // Ensure the input text fits within the buffer
    // 确保 输入 text fits within 缓冲区
    if (text.len > buffer.len) {
        std.debug.print("Error: text too long (max {d} chars)\n", .{buffer.len});
        return;
    }

    // Copy input text into the mutable buffer for reversal
    // 复制 输入 text into mutable 缓冲区 用于 reversal
    @memcpy(buffer[0..text.len], text);
    
    // Perform in-place reversal using textkit utility
    // 执行 在-place reversal 使用 textkit 工具函数
    textkit.StringUtils.reverse(buffer[0..text.len]);

    // Display both the original and reversed text
    // 显示 both 原始 和 reversed text
    std.debug.print("Original: {s}\n", .{text});
    std.debug.print("Reversed: {s}\n", .{buffer[0..text.len]});
}

// / Count occurrences of a specific character in the provided text
// / Count occurrences 的 一个 specific character 在 provided text
fn countCharacter(text: []const u8, char: u8) !void {
    // Use textkit to count character occurrences
    // Use textkit 到 count character occurrences
    const count = textkit.StringUtils.countChar(text, char);
    
    // Display the count result
    // 显示 count result
    std.debug.print("Character '{c}' appears {d} time(s) in: {s}\n", .{
        char,
        count,
        text,
    });
}

// Test that all declarations in this module are reachable and compile correctly
// Test 该 所有 declarations 在 此 module are reachable 和 编译 correctly
test "main program compiles" {
    std.testing.refAllDecls(@This());
}
