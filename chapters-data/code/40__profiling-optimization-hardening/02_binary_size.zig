// 此程序演示了编译时配置如何影响二进制文件大小
// 通过根据构建模式有条件地启用调试跟踪。
const std = @import("std");
const builtin = @import("builtin");

// 编译时标志，仅在 Debug 模式下启用跟踪
// 这演示了死代码消除在发布构建中的工作方式
const enable_tracing = builtin.mode == .Debug;

// 计算给定单词的 FNV-1a 哈希值
// FNV-1a 是一种快速、非密码学的哈希函数
// @param word: 要哈希的输入字节切片
// @return: 64 位哈希值
fn checksumWord(word: []const u8) u64 {
    // FNV-1a 64 位偏移基数
    var state: u64 = 0xcbf29ce484222325;

    // 处理输入的每个字节
    for (word) |byte| {
        // 与当前字节进行异或
        state ^= byte;
        // 乘以 FNV-1a 64 位素数（带环绕乘法）
        state = state *% 0x100000001b3;
    }
    return state;
}

pub fn main() !void {
    // 示例单词列表以演示校验和功能
    const words = [_][]const u8{ "profiling", "optimization", "hardening", "zig" };

    // 组合所有单词校验和的累加器
    var digest: u64 = 0;

    // 处理每个单词并组合其校验和
    for (words) |word| {
        const word_sum = checksumWord(word);
        // 使用 XOR 组合校验和
        digest ^= word_sum;

        // 条件跟踪，将在发布构建中编译掉
        // 这演示了构建模式如何影响二进制文件大小
        if (enable_tracing) {
            std.debug.print("trace: {s} -> {x}\n", .{ word, word_sum });
        }
    }

    // 输出最终结果以及当前构建模式
    // 展示了相同的代码如何根据编译设置表现不同
    std.debug.print(
        "mode={s} digest={x}\n",
        .{
            @tagName(builtin.mode),
            digest,
        },
    );
}
