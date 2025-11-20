const std = @import("std");

test "no leak when freeing properly" {
    // Use the testing allocator, which tracks allocations and detects leaks
    // Use testing allocator, which tracks allocations 和 detects leaks
    const allocator = std.testing.allocator;

    // Allocate a 64-byte buffer on the heap
    // 分配 一个 64-byte 缓冲区 在 堆
    const buf = try allocator.alloc(u8, 64);
    // Schedule deallocation to happen at scope exit (ensures cleanup)
    // Schedule deallocation 到 happen 在 scope 退出 (确保 cleanup)
    defer allocator.free(buf);

    // Fill the buffer with 0xAA pattern to demonstrate usage
    // Fill 缓冲区 使用 0xAA pattern 到 demonstrate usage
    for (buf) |*b| b.* = 0xAA;
    
    // When the test exits, defer runs allocator.free(buf)
    // 当 test exits, defer runs allocator.释放(buf)
    // The testing allocator verifies all allocations were freed
    // testing allocator verifies 所有 allocations were freed
}
