// 导入标准库以获取核心工具
const std = @import("std");

// 常用类型的类型别名
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList(u8);

/// 通过追加文本来高效构造字符串的动态字符串构建器。
/// 跟踪内存增长事件以帮助理解分配模式。
pub const StringBuilder = struct {
    allocator: Allocator,
    list: ArrayList = ArrayList.empty,
    /// 计数器，用于跟踪底层缓冲区增长的次数
    growth_events: usize = 0,

    /// 与std.io.Writer兼容的Writer接口，用于格式化输出
    pub const Writer = std.io.GenericWriter(*StringBuilder, Allocator.Error, writeFn);

    /// 创建没有初始容量的新StringBuilder
    pub fn init(allocator: Allocator) StringBuilder {
        return .{
            .allocator = allocator,
            .list = ArrayList.empty,
            .growth_events = 0,
        };
    }

    /// 创建具有预分配容量的新StringBuilder以减少重新分配
    pub fn initCapacity(allocator: Allocator, initial_capacity: usize) Allocator.Error!StringBuilder {
        var list = ArrayList.empty;
        // 预先分配确切容量以避免初始增长事件
        try list.ensureTotalCapacityPrecise(allocator, initial_capacity);
        return .{
            .allocator = allocator,
            .list = list,
            .growth_events = 0,
        };
    }

    /// 释放所有分配的内存
    pub fn deinit(self: *StringBuilder) void {
        self.list.deinit(self.allocator);
    }

    /// 内部辅助函数，用于检测和计数容量变化
    fn trackGrowth(self: *StringBuilder, prev_capacity: usize) void {
        if (self.list.capacity != prev_capacity) {
            self.growth_events += 1;
        }
    }

    /// 将文本切片追加到构建器
    pub fn append(self: *StringBuilder, text: []const u8) Allocator.Error!void {
        const before = self.list.capacity;
        try self.list.appendSlice(self.allocator, text);
        self.trackGrowth(before);
    }

    /// 将单个字节追加到构建器
    pub fn appendByte(self: *StringBuilder, byte: u8) Allocator.Error!void {
        const before = self.list.capacity;
        try self.list.append(self.allocator, byte);
        self.trackGrowth(before);
    }

    /// 确保构建器在没有重新分配的情况下至少有'additional'更多字节的空间
    pub fn ensureUnusedCapacity(self: *StringBuilder, additional: usize) Allocator.Error!void {
        const before = self.list.capacity;
        try self.list.ensureUnusedCapacity(self.allocator, additional);
        self.trackGrowth(before);
    }

    /// 返回Writer接口，用于std.fmt.format等格式化函数
    pub fn writer(self: *StringBuilder) Writer {
        return .{ .context = self };
    }

    /// 实现Writer接口的内部写入函数
    fn writeFn(self: *StringBuilder, chunk: []const u8) Allocator.Error!usize {
        try self.append(chunk);
        return chunk.len;
    }

    /// 清除内容，同时保持分配的容量以便重复使用
    pub fn reset(self: *StringBuilder) void {
        self.list.clearRetainingCapacity();
        self.growth_events = 0;
    }

    /// 将构建字符串的所有权转移给调用者，重置构建器
    pub fn toOwnedSlice(self: *StringBuilder) Allocator.Error![]u8 {
        return try self.list.toOwnedSlice(self.allocator);
    }

    /// 返回有关构建器当前状态的统计信息而不修改它
    pub fn snapshot(self: *const StringBuilder) Stats {
        return .{
            .length = self.list.items.len,
            .capacity = self.list.capacity,
            .growth_events = self.growth_events,
        };
    }
};

/// StringBuilder当前状态的统计快照
pub const Stats = struct {
    length: usize,
    capacity: usize,
    growth_events: usize,

    /// 自定义格式化器，以可读格式显示统计信息
    pub fn format(self: Stats, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try writer.print("len={d} cap={d} growths={d}", .{ self.length, self.capacity, self.growth_events });
    }
};
