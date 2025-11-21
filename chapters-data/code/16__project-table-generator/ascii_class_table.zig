const std = @import("std");

/// 辅助函数，获取缓冲的标准输出写入器。
/// 使用静态缓冲区避免重复分配。
fn stdout() *std.Io.Writer {
    const g = struct {
        var buf: [4096]u8 = undefined;
        var w = std.fs.File.stdout().writer(&buf);
    };
    return &g.w.interface;
}

/// 表示ASCII字符类的位标志。
/// 可以使用按位OR组合多个标志。
const Class = struct {
    pub const digit: u8 = 0x01;  // 0-9
    pub const alpha: u8 = 0x02;  // A-Z, a-z
    pub const space: u8 = 0x04;  // 空格、换行、制表符、回车
    pub const punct: u8 = 0x08;  // 标点符号
};

/// 构建查找表，将每个字节（0-255）映射到其字符类标志。
/// 此函数在编译时运行，产生嵌入在二进制文件中的常量表。
fn buildAsciiClassTable() [256]u8 {
    // 将所有条目初始化为0（未设置类标志）
    var t: [256]u8 = .{0} ** 256;

    // 在编译时迭代所有可能的字节值
    comptime var b: usize = 0;
    inline while (b < 256) : (b += 1) {
        const ch: u8 = @intCast(b);
        var m: u8 = 0;  // 类标志的累加器

        // 检查字符是否为数字（0-9）
        if (ch >= '0' and ch <= '9') m |= Class.digit;

        // 检查字符是否为字母（A-Z或a-z）
        if ((ch >= 'A' and ch <= 'Z') or (ch >= 'a' and ch <= 'z')) m |= Class.alpha;

        // 检查字符是否为空白字符（空格、换行、制表符、回车）
        if (ch == ' ' or ch == '\n' or ch == '\t' or ch == '\r') m |= Class.space;

        // 检查字符是否为标点符号（可打印、非字母数字、非空白）
        if (std.ascii.isPrint(ch) and !std.ascii.isAlphanumeric(ch) and !std.ascii.isWhitespace(ch)) m |= Class.punct;

        // 为此字节值存储计算出的标志
        t[b] = m;
    }
    return t;
}

/// 计算输入字符串中每个字符类的出现次数。
/// 使用预计算的查找表实现每个字符的O(1)分类。
fn countKinds(s: []const u8) struct { digits: usize, letters: usize, spaces: usize, punct: usize } {
    // 构建分类表（在编译时发生）
    const T = buildAsciiClassTable();

    // 为每个字符类初始化计数器
    var c = struct { digits: usize = 0, letters: usize = 0, spaces: usize = 0, punct: usize = 0 }{};

    // 遍历输入字符串中的每个字节
    var i: usize = 0;
    while (i < s.len) : (i += 1) {
        // 查找当前字节的类标志
        const m = T[s[i]];

        // 测试每个标志并增加相应的计数器
        if ((m & Class.digit) != 0) c.digits += 1;
        if ((m & Class.alpha) != 0) c.letters += 1;
        if ((m & Class.space) != 0) c.spaces += 1;
        if ((m & Class.punct) != 0) c.punct += 1;
    }

    // 返回计数作为匿名结构
    return .{ .digits = c.digits, .letters = c.letters, .spaces = c.spaces, .punct = c.punct };
}

pub fn main() !void {
    // 获取缓冲输出写入器
    const out = stdout();

    // 定义包含各种字符类的测试字符串
    const s = "Hello, Zig 0.15.2!  \t\n";

    // 计算测试字符串中每个字符类
    const c = countKinds(s);

    // 打印输入字符串
    try out.print("input: {s}\n", .{s});

    // 打印每个字符类的计算计数
    try out.print("digits={} letters={} spaces={} punct={}\n", .{ c.digits, c.letters, c.spaces, c.punct });

    // 确保缓冲输出写入stdout
    try out.flush();
}
