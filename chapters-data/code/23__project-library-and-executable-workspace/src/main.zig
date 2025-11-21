const std = @import("std");
const textkit = @import("textkit");

pub fn main() !void {
    // 设置通用分配器用于动态内存分配
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // 检索传递给程序的命令行参数
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    // 确保至少提供一个命令参数（args[0]是程序名）
    if (args.len < 2) {
        try printUsage();
        return;
    }

    // 从第一个参数中提取命令动词
    const command = args[1];

    // 根据命令分派到适当的处理程序
    if (std.mem.eql(u8, command, "analyze")) {
        // 'analyze'需要一个文件名参数
        if (args.len < 3) {
            std.debug.print("Error: analyze requires a filename\n", .{});
            return;
        }
        try analyzeFile(allocator, args[2]);
    } else if (std.mem.eql(u8, command, "reverse")) {
        // 'reverse'需要反转的文本
        if (args.len < 3) {
            std.debug.print("Error: reverse requires text\n", .{});
            return;
        }
        try reverseText(args[2]);
    } else if (std.mem.eql(u8, command, "count")) {
        // 'count'需要文本和要计数的单个字符
        if (args.len < 4) {
            std.debug.print("Error: count requires text and character\n", .{});
            return;
        }
        // 验证字符参数恰好是一个字节
        if (args[3].len != 1) {
            std.debug.print("Error: character must be single byte\n", .{});
            return;
        }
        try countCharacter(args[2], args[3][0]);
    } else {
        // 处理无法识别的命令
        std.debug.print("Unknown command: {s}\n", .{command});
        try printUsage();
    }
}

/// 打印使用说明以指导用户了解可用命令
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

/// 读取文件并显示其文本内容的统计分析
fn analyzeFile(allocator: std.mem.Allocator, filename: []const u8) !void {
    // 从当前工作目录以只读模式打开文件
    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    // 将整个文件内容读取到内存（限制为1MB）
    const content = try file.readToEndAlloc(allocator, 1024 * 1024);
    defer allocator.free(content);

    // 使用textkit库计算文本统计信息
    const stats = textkit.TextStats.analyze(content);

    // 向用户显示计算出的统计信息
    std.debug.print("File: {s}\n", .{filename});
    std.debug.print("  Lines: {d}\n", .{stats.line_count});
    std.debug.print("  Words: {d}\n", .{stats.word_count});
    std.debug.print("  Characters: {d}\n", .{stats.char_count});
    std.debug.print("  ASCII only: {}\n", .{textkit.StringUtils.isAscii(content)});
}

/// 反转提供的文本并显示原始和反转版本
fn reverseText(text: []const u8) !void {
    // 为就地反转分配栈缓冲区
    var buffer: [1024]u8 = undefined;

    // 确保输入文本适合缓冲区
    if (text.len > buffer.len) {
        std.debug.print("Error: text too long (max {d} chars)\n", .{buffer.len});
        return;
    }

    // 将输入文本复制到可变缓冲区中进行反转
    @memcpy(buffer[0..text.len], text);

    // 使用textkit实用工具执行就地反转
    textkit.StringUtils.reverse(buffer[0..text.len]);

    // 显示原始和反转文本
    std.debug.print("Original: {s}\n", .{text});
    std.debug.print("Reversed: {s}\n", .{buffer[0..text.len]});
}

/// 计算提供文本中特定字符的出现次数
fn countCharacter(text: []const u8, char: u8) !void {
    // 使用textkit计算字符出现次数
    const count = textkit.StringUtils.countChar(text, char);

    // 显示计数结果
    std.debug.print("Character '{c}' appears {d} time(s) in: {s}\n", .{
        char,
        count,
        text,
    });
}

// 测试此模块中的所有声明是否可访问并正确编译
test "main program compiles" {
    std.testing.refAllDecls(@This());
}
