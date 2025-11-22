const std = @import("std");
const builtin = @import("builtin");

// / 映射类型别名：单词 → 频率计数
const Map = std.StringHashMap(u64);

// / 通过将ASCII字母转换为小写来规范化原始token，并
// / 从两端剥离非字母数字字符。
// / 返回指向所提供缓冲区的切片；调用者拥有该缓冲区。
fn normalizeWord(allocator: std.mem.Allocator, raw: []const u8) ![]const u8 {
    // 分配一个足够大的缓冲区以容纳整个输入
    var buf = try allocator.alloc(u8, raw.len);
    var n: usize = 0;

    // 将大写ASCII转换为小写 (A-Z → a-z)
    for (raw) |c| {
        var ch = c;
        if (ch >= 'A' and ch <= 'Z') ch = ch + 32;
        buf[n] = ch;
        n += 1;
    }

    // 剥离前导非字母数字字符
    var start: usize = 0;
    while (start < n and (buf[start] < '0' or (buf[start] > '9' and buf[start] < 'a') or buf[start] > 'z')) : (start += 1) {}

    // 剥离尾随非字母数字字符
    var end: usize = n;
    while (end > start and (buf[end - 1] < '0' or (buf[end - 1] > '9' and buf[end - 1] < 'a') or buf[end - 1] > 'z')) : (end -= 1) {}

    // 如果剥离后没有剩余，则返回空切片
    if (end <= start) return buf[0..0];
    return buf[start..end];
}

// / 在空白处对文本进行token化，并使用提供的映射填充
/// 规范化的单词频率。键是从提供的分配器中
// / 分配的规范化副本。
fn tokenizeAndCount(allocator: std.mem.Allocator, text: []const u8, map: *Map) !void {
    // 在任意空白字符处分割
    var it = std.mem.tokenizeAny(u8, text, " \t\r\n");
    while (it.next()) |raw| {
        const word = try normalizeWord(allocator, raw);
        if (word.len == 0) continue; // skip empty tokens

        // 插入或更新单词计数
        const gop = try map.getOrPut(word);
        if (!gop.found_existing) {
            gop.value_ptr.* = 1;
        } else {
            gop.value_ptr.* += 1;
        }
    }
}

// / 传递给每个工作线程的参数
const WorkerArgs = struct {
    slice: []const u8, // 要处理的文本段
    counts: *Map, // 线程本地频率映射
    arena: *std.heap.ArenaAllocator, // 用于临时分配的 arena
};

// / 每个线程执行的工作函数；token化并计数单词
// / 在其分配的文本段中，不共享状态。
fn countWorker(args: WorkerArgs) void {
    // 每个工作线程只写入自己的映射实例；合并稍后发生
    tokenizeAndCount(args.arena.allocator(), args.slice, args.counts) catch |err| {
        std.debug.print("worker error: {s}\n", .{@errorName(err)});
    };
}

// / 将整个文件读取到新分配的缓冲区中，上限为 64 MiB。
fn readAllAlloc(path: []const u8, allocator: std.mem.Allocator) ![]u8 {
    var file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
    return try file.readToEndAlloc(allocator, 64 * 1024 * 1024);
}

/// 将文本分区为大致相等的片段，确保分片边界
// / 落在空白处以避免分割单词。返回切片的拥有切片。
fn shard(text: []const u8, shards: usize, allocator: std.mem.Allocator) ![]const []const u8 {
    // 如果只请求一个分片或文本为空，则返回单个片段
    if (shards <= 1 or text.len == 0) {
        var single = try allocator.alloc([]const u8, 1);
        single[0] = text;
        return single;
    }

    const approx = text.len / shards; // 每个分片的近似字节数
    var parts = std.array_list.Managed([]const u8).init(allocator);
    defer parts.deinit();

    var i: usize = 0;
    while (i < text.len) {
        var end = @min(text.len, i + approx);

        // 将分片边界向前推进到下一个空白字符
        while (end < text.len and text[end] != ' ' and text[end] != '\n' and text[end] != '\t' and text[end] != '\r') : (end += 1) {}

        // 如果没有找到空白，则回退到近似边界
        if (end == i) end = @min(text.len, i + approx);

        try parts.append(text[i..end]);
        i = end;
    }
    return try parts.toOwnedSlice();
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // 设置缓冲标准输出以实现高效打印
    var stdout_buf: [1024]u8 = undefined;
    var stdout_state = std.fs.File.stdout().writer(&stdout_buf);
    const out = &stdout_state.interface;

    // 解析命令行参数
    var args_it = try std.process.argsWithAllocator(allocator);
    defer args_it.deinit();

    _ = args_it.next(); // 跳过程序名
    const path = args_it.next() orelse {
        try out.print("usage: parallel-wc <file>\n", .{});
        try out.flush();
        return;
    };

    // 将整个文件读入内存
    const text = try readAllAlloc(path, allocator);
    defer allocator.free(text);

    // 确定分片计数：除非是单线程构建，否则使用 CPU 计数
    const cpu = std.Thread.getCpuCount() catch 1;
    const shard_count = if (builtin.single_threaded) 1 else if (cpu < 1) 1 else cpu;

    // 在空白边界处将文本分区为分片
    const parts = try shard(text, shard_count, allocator);
    defer allocator.free(parts);

    // 分配每个分片的 arena 和 map
    var arenas = try allocator.alloc(std.heap.ArenaAllocator, parts.len);
    defer allocator.free(arenas);

    var maps = try allocator.alloc(Map, parts.len);
    defer allocator.free(maps);

    // 如果是多线程，则分配线程句柄
    var threads = if (builtin.single_threaded) &[_]std.Thread{} else try allocator.alloc(std.Thread, parts.len);
    defer if (!builtin.single_threaded) allocator.free(threads);

    // 启动工作线程（如果是单线程，则内联执行）
    for (parts, 0..) |seg, i| {
        arenas[i] = std.heap.ArenaAllocator.init(allocator);
        maps[i] = Map.init(allocator);
        try maps[i].ensureTotalCapacity(1024); // 预设大小以减少重新哈希

        if (builtin.single_threaded) {
            // 内联执行 worker
            countWorker(.{ .slice = seg, .counts = &maps[i], .arena = &arenas[i] });
        } else {
            // 为此分片启动一个线程
            threads[i] = try std.Thread.spawn(.{}, countWorker, .{WorkerArgs{ .slice = seg, .counts = &maps[i], .arena = &arenas[i] }});
        }
    }

    // 等待所有线程完成
    if (!builtin.single_threaded) {
        for (threads) |t| t.join();
    }

    // 将每个线程的 map 合并到一个全局 map 中
    var total = Map.init(allocator);
    defer total.deinit();
    try total.ensureTotalCapacity(4096); // 预设合并数据的大小

    for (maps, 0..) |*m, i| {
        var it = m.iterator();
        while (it.next()) |e| {
            const key_bytes = e.key_ptr.*;

            // 将键复制到 total 的分配器中以获取所有权，
            // 因为 arena 很快就会被释放
            const dup = try allocator.dupe(u8, key_bytes);
            const gop = try total.getOrPut(dup);

            if (!gop.found_existing) {
                gop.value_ptr.* = e.value_ptr.*;
            } else {
                // 键已存在；释放重复项并累加计数
                allocator.free(dup);
                gop.value_ptr.* += e.value_ptr.*;
            }
        }

        // 释放每个线程的 arena 和 map
        arenas[i].deinit();
        m.deinit();
    }

    // 构建可排序的 (单词, 计数) 条目列表
    const Entry = struct { k: []const u8, v: u64 };
    var entries = std.array_list.Managed(Entry).init(allocator);
    defer entries.deinit();

    var it = total.iterator();
    while (it.next()) |e| {
        try entries.append(.{ .k = e.key_ptr.*, .v = e.value_ptr.* });
    }

    // Sort by count descending, then alphabetically
    std.sort.pdq(Entry, entries.items, {}, struct {
        fn lessThan(_: void, a: Entry, b: Entry) bool {
            if (a.v == b.v) return std.mem.lessThan(u8, a.k, b.k);
            return a.v > b.v; // 按计数降序
        }
    }.lessThan);

    // Print top 10 most frequent words
    const to_show = @min(entries.items.len, 10);
    try out.print("top {d} words in {d} shards:\n", .{ to_show, parts.len });
    for (entries.items[0..to_show]) |e| {
        try out.print("{s} {d}\n", .{ e.k, e.v });
    }

    // 现在我们已经处理完 map，释放重复的键
    var free_it = total.iterator();
    while (free_it.next()) |e| allocator.free(e.key_ptr.*);

    try out.flush();
}
