
// This program demonstrates how compile-time configuration affects binary size
// 此 program 演示 how 编译-time configuration affects binary size
// by conditionally enabling debug tracing based on the build mode.
// 通过 conditionally enabling 调试 tracing 基于 构建模式.
const std = @import("std");
const builtin = @import("builtin");

// Compile-time flag that enables tracing only in Debug mode
// 编译-time flag 该 enables tracing only 在 调试模式
// This demonstrates how dead code elimination works in release builds
// 此 演示 how dead 代码 elimination works 在 发布 builds
const enable_tracing = builtin.mode == .Debug;

// Computes a FNV-1a hash for a given word
// Computes 一个 FNV-1a hash 用于 一个 given word
// FNV-1a is a fast, non-cryptographic hash function
// FNV-1a is 一个 fast, non-cryptographic hash 函数
// @param word: The input byte slice to hash
// @param word: 输入 byte 切片 到 hash
// @return: A 64-bit hash value
// @返回: 一个 64-bit hash 值
fn checksumWord(word: []const u8) u64 {
    // FNV-1a 64-bit offset basis
    var state: u64 = 0xcbf29ce484222325;
    
    // Process each byte of the input
    // Process 每个 byte 的 输入
    for (word) |byte| {
        // XOR with the current byte
        // XOR 使用 当前 byte
        state ^= byte;
        // Multiply by FNV-1a 64-bit prime (with wrapping multiplication)
        // Multiply 通过 FNV-1a 64-bit prime (使用 wrapping multiplication)
        state = state *% 0x100000001b3;
    }
    return state;
}

pub fn main() !void {
    // Sample word list to demonstrate the checksum functionality
    // Sample word list 到 demonstrate checksum functionality
    const words = [_][]const u8{ "profiling", "optimization", "hardening", "zig" };
    
    // Accumulator for combining all word checksums
    // Accumulator 用于 combining 所有 word checksums
    var digest: u64 = 0;
    
    // Process each word and combine their checksums
    // Process 每个 word 和 combine their checksums
    for (words) |word| {
        const word_sum = checksumWord(word);
        // Combine checksums using XOR
        // Combine checksums 使用 XOR
        digest ^= word_sum;
        
        // Conditional tracing that will be compiled out in release builds
        // Conditional tracing 该 will be compiled out 在 发布 builds
        // This demonstrates how build mode affects binary size
        // 此 演示 how 构建模式 affects binary size
        if (enable_tracing) {
            std.debug.print("trace: {s} -> {x}\n", .{ word, word_sum });
        }
    }

    // Output the final result along with the current build mode
    // 输出 最终 result along 使用 当前 构建模式
    // Shows how the same code behaves differently based on compilation settings
    // Shows how same 代码 behaves differently 基于 compilation settings
    std.debug.print(
        "mode={s} digest={x}\n",
        .{
            @tagName(builtin.mode),
            digest,
        },
    );
}
