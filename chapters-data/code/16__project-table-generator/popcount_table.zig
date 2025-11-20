const std = @import("std");

// / Returns a reference to a buffered stdout writer.
// / 返回 一个 reference 到 一个 缓冲 stdout writer.
// / The buffer and writer are stored in a private struct to persist across calls.
// / 缓冲区 和 writer are stored 在 一个 private struct 到 persist across calls.
fn stdout() *std.Io.Writer {
    const g = struct {
        // Static buffer for stdout writes—survives function returns
        // Static 缓冲区 用于 stdout writes—survives 函数 返回
        var buf: [4096]u8 = undefined;
        // Writer wraps stdout with the buffer; created once
        // Writer wraps stdout 使用 缓冲区; created once
        var w = std.fs.File.stdout().writer(&buf);
    };
    // Return pointer to the writer's generic interface
    // 返回 pointer 到 writer's 通用 接口
    return &g.w.interface;
}

// / Counts the number of set bits (1s) in a single byte using bit manipulation.
// / Counts 数字 的 set bits (1s) 在 一个 single byte 使用 bit manipulation.
// / Uses a well-known parallel popcount algorithm that avoids branches.
// / 使用 一个 well-known parallel popcount algorithm 该 avoids branches.
fn popcountByte(x: u8) u8 {
    var v = x;
    // Step 1: Count bits in pairs (2-bit groups)
    // Step 1: Count bits 在 pairs (2-bit groups)
    // Subtracts neighbor bit from each 2-bit group to get counts 0-2
    // Subtracts neighbor bit 从 每个 2-bit group 到 获取 counts 0-2
    v = v - ((v >> 1) & 0x55);
    // Step 2: Count bits in nibbles (4-bit groups)
    // Step 2: Count bits 在 nibbles (4-bit groups)
    // Adds adjacent 2-bit counts to get nibble counts 0-4
    // Adds adjacent 2-bit counts 到 获取 nibble counts 0-4
    v = (v & 0x33) + ((v >> 2) & 0x33);
    // Step 3: Combine nibbles and mask low 4 bits (result 0-8)
    // Step 3: Combine nibbles 和 mask low 4 bits (result 0-8)
    // Adding the two nibbles gives total count, truncate to u8
    // Adding 两个 nibbles gives total count, truncate 到 u8
    return @truncate(((v + (v >> 4)) & 0x0F));
}

// / Builds a 256-entry lookup table at compile time.
// / Builds 一个 256-entry lookup table 在 编译时.
// / Each entry [i] holds the number of set bits in byte value i.
// / 每个 entry [i] holds 数字 的 set bits 在 byte 值 i.
fn buildPopcountTable() [256]u8 {
    // Initialize table with zeros (all 256 entries)
    // Initialize table 使用 zeros (所有 256 entries)
    var t: [256]u8 = .{0} ** 256;
    // Compile-time loop index (required for inline while)
    // 编译-time loop 索引 (必需 用于 inline 当)
    comptime var i: usize = 0;
    // Unrolled loop: compute popcount for each possible byte value
    // Unrolled loop: compute popcount 用于 每个 possible byte 值
    inline while (i < 256) : (i += 1) {
        // Store the bit count for byte value i
        // Store bit count 用于 byte 值 i
        t[i] = popcountByte(@intCast(i));
    }
    // Return the fully populated table as a compile-time constant
    // 返回 fully populated table 作为 一个 编译-time constant
    return t;
}

pub fn main() !void {
    // Acquire the buffered stdout writer
    // Acquire 缓冲 stdout writer
    const out = stdout();
    
    // Generate the popcount lookup table at compile time
    // Generate popcount lookup table 在 编译时
    const T = buildPopcountTable();
    
    // Test data: array of bytes to analyze
    // Test 数据: 数组 的 bytes 到 analyze
    const bytes = [_]u8{ 0x00, 0x0F, 0xF0, 0xAA, 0xFF };
    
    // Accumulator for total set bits across all test bytes
    // Accumulator 用于 total set bits across 所有 test bytes
    var sum: usize = 0;
    
    // Sum up set bits by indexing into the precomputed table
    // Sum up set bits 通过 indexing into precomputed table
    for (bytes) |b| sum += T[b];
    
    // Print label for the output
    // 打印 标签 用于 输出
    try out.print("bytes: ", .{});
    
    // Print each byte in hex format with spacing
    // 打印 每个 byte 在 hex format 使用 spacing
    for (bytes, 0..) |b, idx| {
        // Add space separator between bytes (not before first)
        // Add space separator between bytes (不 before 首先)
        if (idx != 0) try out.print(" ", .{});
        // Format as 0x-prefixed 2-digit hex (e.g., 0x0F)
        // Format 作为 0x-prefixed 2-digit hex (e.g., 0x0F)
        try out.print("0x{X:0>2}", .{b});
    }
    
    // Print the final sum of all set bits
    // 打印 最终 sum 的 所有 set bits
    try out.print(" -> total set bits = {}\n", .{sum});
    
    // Flush the buffered writer to ensure all output appears
    // 刷新 缓冲写入器 到 确保 所有 输出 appears
    try out.flush();
}
