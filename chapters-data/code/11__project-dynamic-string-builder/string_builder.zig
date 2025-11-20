
// Import the standard library for core utilities
// 导入标准库 用于 core utilities
const std = @import("std");

// Type aliases for commonly used types
// 类型 aliases 用于 commonly used 类型
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList(u8);

// / A dynamic string builder that efficiently constructs strings by appending text.
// / 一个 dynamic string builder 该 efficiently constructs 字符串 通过 appending text.
// / Tracks memory growth events to help understand allocation patterns.
// / Tracks 内存 growth events 到 help understand allocation patterns.
pub const StringBuilder = struct {
    allocator: Allocator,
    list: ArrayList = ArrayList.empty,
    // / Counter for tracking how many times the underlying buffer has grown
    // / Counter 用于 tracking how many times underlying 缓冲区 has grown
    growth_events: usize = 0,

    // / Writer interface compatible with std.io.Writer for formatted output
    // / Writer 接口 compatible 使用 std.io.Writer 用于 格式化 输出
    pub const Writer = std.io.GenericWriter(*StringBuilder, Allocator.Error, writeFn);

    // / Creates a new StringBuilder with no initial capacity
    // / Creates 一个 新 StringBuilder 使用 不 初始 capacity
    pub fn init(allocator: Allocator) StringBuilder {
        return .{
            .allocator = allocator,
            .list = ArrayList.empty,
            .growth_events = 0,
        };
    }

    // / Creates a new StringBuilder with a pre-allocated capacity to reduce reallocations
    // / Creates 一个 新 StringBuilder 使用 一个 pre-allocated capacity 到 reduce reallocations
    pub fn initCapacity(allocator: Allocator, initial_capacity: usize) Allocator.Error!StringBuilder {
        var list = ArrayList.empty;
        // Allocate exact capacity upfront to avoid initial growth events
        // 分配 exact capacity upfront 到 avoid 初始 growth events
        try list.ensureTotalCapacityPrecise(allocator, initial_capacity);
        return .{
            .allocator = allocator,
            .list = list,
            .growth_events = 0,
        };
    }

    // / Frees all allocated memory
    // / Frees 所有 allocated 内存
    pub fn deinit(self: *StringBuilder) void {
        self.list.deinit(self.allocator);
    }

    // / Internal helper to detect and count capacity changes
    // / Internal helper 到 detect 和 count capacity changes
    fn trackGrowth(self: *StringBuilder, prev_capacity: usize) void {
        if (self.list.capacity != prev_capacity) {
            self.growth_events += 1;
        }
    }

    // / Appends a text slice to the builder
    // / Appends 一个 text 切片 到 builder
    pub fn append(self: *StringBuilder, text: []const u8) Allocator.Error!void {
        const before = self.list.capacity;
        try self.list.appendSlice(self.allocator, text);
        self.trackGrowth(before);
    }

    // / Appends a single byte to the builder
    // / Appends 一个 single byte 到 builder
    pub fn appendByte(self: *StringBuilder, byte: u8) Allocator.Error!void {
        const before = self.list.capacity;
        try self.list.append(self.allocator, byte);
        self.trackGrowth(before);
    }

    // / Ensures the builder has space for at least 'additional' more bytes without reallocation
    // / 确保 builder has space 用于 在 least 'additional' more bytes without reallocation
    pub fn ensureUnusedCapacity(self: *StringBuilder, additional: usize) Allocator.Error!void {
        const before = self.list.capacity;
        try self.list.ensureUnusedCapacity(self.allocator, additional);
        self.trackGrowth(before);
    }

    // / Returns a Writer interface for use with formatting functions like std.fmt.format
    // / 返回 一个 Writer 接口 用于 use 使用 formatting 函数 like std.fmt.format
    pub fn writer(self: *StringBuilder) Writer {
        return .{ .context = self };
    }

    // / Internal write function that implements the Writer interface
    // / Internal 写入 函数 该 implements Writer 接口
    fn writeFn(self: *StringBuilder, chunk: []const u8) Allocator.Error!usize {
        try self.append(chunk);
        return chunk.len;
    }

    // / Clears the content while keeping allocated capacity for reuse
    // / Clears content 当 keeping allocated capacity 用于 reuse
    pub fn reset(self: *StringBuilder) void {
        self.list.clearRetainingCapacity();
        self.growth_events = 0;
    }

    // / Transfers ownership of the built string to the caller, resetting the builder
    // / Transfers ownership 的 built string 到 caller, resetting builder
    pub fn toOwnedSlice(self: *StringBuilder) Allocator.Error![]u8 {
        return try self.list.toOwnedSlice(self.allocator);
    }

    // / Returns current statistics about the builder's state without modifying it
    // / 返回 当前 statistics about builder's state without modifying it
    pub fn snapshot(self: *const StringBuilder) Stats {
        return .{
            .length = self.list.items.len,
            .capacity = self.list.capacity,
            .growth_events = self.growth_events,
        };
    }
};

// / Statistics snapshot of a StringBuilder's current state
// / Statistics snapshot 的 一个 StringBuilder's 当前 state
pub const Stats = struct {
    length: usize,
    capacity: usize,
    growth_events: usize,

    // / Custom formatter for displaying stats in a readable format
    // / 自定义 formatter 用于 displaying stats 在 一个 readable format
    pub fn format(self: Stats, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try writer.print("len={d} cap={d} growths={d}", .{ self.length, self.capacity, self.growth_events });
    }
};
