// File: chapters-data/code/01__boot-basics/buffered_stdout.zig
const std = @import("std");

pub fn main() !void {
    // Allocate a 256-byte buffer on the stack for output batching
    // 分配 一个 256-byte 缓冲区 在 栈 用于 输出 batching
    // This buffer accumulates write operations to minimize syscalls
    // 此 缓冲区 accumulates 写入 operations 到 minimize syscalls
    var stdout_buffer: [256]u8 = undefined;
    
    // Create a buffered writer wrapping stdout
    // 创建一个 缓冲写入器 wrapping stdout
    // The writer batches output into stdout_buffer before making syscalls
    // writer batches 输出 into stdout_buffer before making syscalls
    var writer_state = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &writer_state.interface;

    // These print calls write to the buffer, not directly to the terminal
    // 这些 打印 calls 写入 到 缓冲区, 不 directly 到 terminal
    // No syscalls occur yet—data accumulates in stdout_buffer
    // 不 syscalls occur yet—数据 accumulates 在 stdout_buffer
    try stdout.print("Buffering saves syscalls.\n", .{});
    try stdout.print("Flush once at the end.\n", .{});
    
    // Explicitly flush the buffer to write all accumulated data at once
    // Explicitly 刷新 缓冲区 到 写入 所有 accumulated 数据 在 once
    // This triggers a single syscall instead of one per print operation
    // 此 triggers 一个 single syscall 而非 一个 per 打印 operation
    try stdout.flush();
}
