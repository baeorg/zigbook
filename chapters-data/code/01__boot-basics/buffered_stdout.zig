// 文件路径: chapters-data/code/01__boot-basics/buffered_stdout.zig
const std = @import("std");

pub fn main() !void {
    // 在栈上分配256字节的缓冲区用于批量输出
    // 此缓冲区聚合写入操作以减少系统调用次数
    var stdout_buffer: [256]u8 = undefined;

    // 创建包装stdout的缓冲写入器
    // 写入器在发起系统调用前将输出批量处理到stdout_buffer
    var writer_state = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &writer_state.interface;

    // 这些打印调用写入缓冲区，而非直接写入终端
    // 此时尚未发生系统调用——数据累积在stdout_buffer中
    try stdout.print("Buffering saves syscalls.\n", .{});
    try stdout.print("Flush once at the end.\n", .{});

    // 显式刷新缓冲区，一次性写入所有累积的数据
    // 这将触发单个系统调用，而非每次打印操作一次
    try stdout.flush();
}
