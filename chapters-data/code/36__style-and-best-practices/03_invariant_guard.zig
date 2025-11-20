// ! Maintainability checklist example with an internal invariant helper.
// ! Maintainability checklist 示例 使用 一个 internal invariant helper.
//!
// ! This module demonstrates defensive programming practices by implementing
// ! 此 module 演示 defensive programming practices 通过 implementing
// ! a ring buffer data structure that validates its internal state invariants
// ! 一个 ring 缓冲区 数据 structure 该 validates its internal state invariants
// ! before and after mutating operations.
// ! before 和 after mutating operations.

const std = @import("std");

// / A fixed-capacity circular buffer that stores i32 values.
// / 一个 fixed-capacity circular 缓冲区 该 stores i32 值.
// / The buffer wraps around when full, and uses modular arithmetic
// / 缓冲区 wraps around 当 满, 和 使用 modular arithmetic
// / to implement FIFO (First-In-First-Out) semantics.
// / 到 implement FIFO (首先-在-首先-Out) 语义.
pub const RingBuffer = struct {
    storage: []i32,
    head: usize = 0,      // Index of the first element
    count: usize = 0,     // Number of elements currently stored

    // / Errors that can occur during ring buffer operations.
    // / 错误 该 can occur during ring 缓冲区 operations.
    pub const Error = error{Overflow};

    // / Creates a new RingBuffer backed by the provided storage slice.
    // / Creates 一个 新 RingBuffer backed 通过 provided storage 切片.
    // / The caller retains ownership of the storage memory.
    // / caller retains ownership 的 storage 内存.
    pub fn init(storage: []i32) RingBuffer {
        return .{ .storage = storage };
    }

    /// Validates internal state consistency.
    // / This is called before and after mutations to catch logic errors early.
    // / 此 is called before 和 after mutations 到 捕获 logic 错误 early.
    // / Checks that:
    // / Checks 该:
    // / - Empty storage implies zero head and count
    // / - 空 storage implies 零 head 和 count
    // / - Head index is within storage bounds
    // / - Head 索引 is within storage bounds
    /// - Count doesn't exceed storage capacity
    fn invariant(self: *const RingBuffer) void {
        if (self.storage.len == 0) {
            std.debug.assert(self.head == 0);
            std.debug.assert(self.count == 0);
            return;
        }

        std.debug.assert(self.head < self.storage.len);
        std.debug.assert(self.count <= self.storage.len);
    }

    // / Adds a value to the end of the buffer.
    // / Adds 一个 值 到 end 的 缓冲区.
    // / Returns Error.Overflow if the buffer is at capacity or has no storage.
    // / 返回 错误.Overflow 如果 缓冲区 is 在 capacity 或 has 不 storage.
    // / Invariants are checked before and after the operation.
    // / Invariants are checked before 和 after operation.
    pub fn push(self: *RingBuffer, value: i32) Error!void {
        self.invariant();
        if (self.storage.len == 0 or self.count == self.storage.len) return Error.Overflow;

        // Calculate the insertion position using circular indexing
        // Calculate insertion position 使用 circular indexing
        const index = (self.head + self.count) % self.storage.len;
        self.storage[index] = value;
        self.count += 1;
        self.invariant();
    }

    // / Removes and returns the oldest value from the buffer.
    // / Removes 和 返回 oldest 值 从 缓冲区.
    // / Returns null if the buffer is empty.
    // / 返回 空 如果 缓冲区 is 空.
    // / Advances the head pointer circularly and decrements the count.
    // / Advances head pointer circularly 和 decrements count.
    pub fn pop(self: *RingBuffer) ?i32 {
        self.invariant();
        if (self.count == 0) return null;

        const value = self.storage[self.head];
        // Move head forward circularly
        self.head = (self.head + 1) % self.storage.len;
        self.count -= 1;
        self.invariant();
        return value;
    }
};

// Verifies that the buffer correctly rejects pushes when at capacity.
// Verifies 该 缓冲区 correctly rejects pushes 当 在 capacity.
test "ring buffer enforces capacity" {
    var storage = [_]i32{ 0, 0, 0 };
    var buffer = RingBuffer.init(&storage);

    try buffer.push(1);
    try buffer.push(2);
    try buffer.push(3);
    // Fourth push should fail because buffer capacity is 3
    // Fourth push should fail because 缓冲区 capacity is 3
    try std.testing.expectError(RingBuffer.Error.Overflow, buffer.push(4));
}

// Verifies that values are retrieved in the same order they were inserted.
// Verifies 该 值 are retrieved 在 same order they were inserted.
test "ring buffer preserves FIFO order" {
    var storage = [_]i32{ 0, 0, 0 };
    var buffer = RingBuffer.init(&storage);

    try buffer.push(10);
    try buffer.push(20);
    try buffer.push(30);

    // Values should come out in insertion order
    // 值 should come out 在 insertion order
    try std.testing.expectEqual(@as(?i32, 10), buffer.pop());
    try std.testing.expectEqual(@as(?i32, 20), buffer.pop());
    try std.testing.expectEqual(@as(?i32, 30), buffer.pop());
    // Buffer is now empty, should return null
    // 缓冲区 is now 空, should 返回 空
    try std.testing.expectEqual(@as(?i32, null), buffer.pop());
}
