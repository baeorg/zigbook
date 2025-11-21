// 导入Zig标准库，用于分配器、排序、调试等
const std = @import("std");

const Order = std.math.Order;

// 单个端点的延迟测量记录。
// 字段：
// - endpoint: 标识端点的UTF-8字节切片
// - duration_ms: 观察到的延迟时间（毫秒）
// - payload_bytes: 请求/响应负载大小（字节）
const LatencySample = struct {
    endpoint: []const u8,
    duration_ms: u32,
    payload_bytes: u32,
};

// 计算延迟样本的分数。
// 分数越高表示样本越严重（更差）。
// 该公式偏爱较长的持续时间，并对较大的负载施加小的惩罚以减少
// 噪声性高延迟大负载样本。
//
// 返回f64以便分数可以与分数惩罚进行比较。
fn score(sample: LatencySample) f64 {
    // 显式将整数转换为浮点数以避免隐式转换。
    // 惩罚因子0.005是通过经验选择且很小。
    return @as(f64, @floatFromInt(sample.duration_ms)) - (@as(f64, @floatFromInt(sample.payload_bytes)) * 0.005);
}

// TopK是一个编译时泛型生产者，返回固定容量的、
// 分数驱动的Top-K跟踪器，用于类型T的项目。
//
// 参数：
// - T: 存储在跟踪器中的元素类型
// - scoreFn: 将T映射到f64的编译时函数，用于对元素排名
fn TopK(comptime T: type, comptime scoreFn: fn (T) f64) type {
    const Error = error{InvalidLimit};

    // 由PriorityQueue和用于排序快照使用的比较器辅助函数
    const Comparators = struct {
        // PriorityQueue使用的比较器。第一个参数是
        // 用户提供的上下文（此处未使用），因此使用下划线名称。
        // 根据分数函数返回Order（Less/Equal/Greater）。
        fn heap(_: void, a: T, b: T) Order {
            return std.math.order(scoreFn(a), scoreFn(b));
        }

        // 堆排序使用的布尔比较器，产生降序。
        // 当`a`应该在`b`之前时返回true（即a有更高的分数）。
        fn desc(_: void, a: T, b: T) bool {
            return scoreFn(a) > scoreFn(b);
        }
    };

    return struct {
        // 使用我们的堆比较器为T特化的优先级队列
        const Heap = std.PriorityQueue(T, void, Comparators.heap);
        const Self = @This();

        heap: Heap,
        limit: usize,

        // 使用提供的分配器和正数限制初始化TopK跟踪器。
        // 当limit == 0时返回Error.InvalidLimit。
        pub fn init(allocator: std.mem.Allocator, limit: usize) Error!Self {
            if (limit == 0) return Error.InvalidLimit;
            return .{ .heap = Heap.init(allocator, {}), .limit = limit };
        }

        // 释放底层堆并释放其资源。
        pub fn deinit(self: *Self) void {
            self.heap.deinit();
        }

        // 向跟踪器添加单个值。如果添加导致内部
        // 计数超过`limit`，优先级队列将根据我们的比较器
        // 逐出它认为优先级最低的项目，保持
        // Top-K分数项目。
        pub fn add(self: *Self, value: T) !void {
            try self.heap.add(value);
            if (self.heap.count() > self.limit) {
                // 逐出优先级最低的元素（如Comparators.heap所定义）。
                _ = self.heap.remove();
            }
        }

        // 从切片向跟踪器添加多个值。
        // 这只是将每个元素转发给`add`。
        pub fn addSlice(self: *Self, values: []const T) !void {
            for (values) |value| try self.add(value);
        }

        // 生成当前跟踪项目按分数降序排列的快照。
        //
        // 快照通过`allocator`分配新数组并复制
        // 内部堆的项目存储到其中。结果随后按
        // 降序（最高分数优先）使用Comparators.desc排序。
        //
        // 调用者负责释放返回的切片。
        pub fn snapshotDescending(self: *Self, allocator: std.mem.Allocator) ![]T {
            const count = self.heap.count();
            const out = try allocator.alloc(T, count);
            // 将底层项目缓冲区复制到新分配的数组中。
            // 这创建了一个独立快照，因此我们可以在不修改堆的情况下排序。
            @memcpy(out, self.heap.items[0..count]);
            // 原地排序，使得分最高的项目出现在前面。
            std.sort.heap(T, out, @as(void, {}), Comparators.desc);
            return out;
        }
    };
}

// 演示TopK与LatencySample一起使用的示例程序
pub fn main() !void {
    // 为示例分配创建通用分配器。
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // 按计算分数跟踪前5个延迟样本。
    var tracker = try TopK(LatencySample, score).init(allocator, 5);
    defer tracker.deinit();

    // 示例样本。这些是小的、栈分配的字面量记录。
    const samples = [_]LatencySample{
        .{ .endpoint = "/v1/users", .duration_ms = 122, .payload_bytes = 850 },
        .{ .endpoint = "/v1/orders", .duration_ms = 210, .payload_bytes = 1200 },
        .{ .endpoint = "/v1/users", .duration_ms = 188, .payload_bytes = 640 },
        .{ .endpoint = "/v1/payments", .duration_ms = 305, .payload_bytes = 1500 },
        .{ .endpoint = "/v1/orders", .duration_ms = 154, .payload_bytes = 700 },
        .{ .endpoint = "/v1/ledger", .duration_ms = 420, .payload_bytes = 540 },
        .{ .endpoint = "/v1/users", .duration_ms = 275, .payload_bytes = 980 },
        .{ .endpoint = "/v1/health", .duration_ms = 34, .payload_bytes = 64 },
        .{ .endpoint = "/v1/ledger", .duration_ms = 362, .payload_bytes = 480 },
    };

    // 批量添加样本切片到跟踪器。
    try tracker.addSlice(&samples);

    // 捕获当前Top-K样本（降序）并打印它们。
    const worst = try tracker.snapshotDescending(allocator);
    defer allocator.free(worst);

    std.debug.print("Top latency offenders (descending by score):\n", .{});
    for (worst, 0..) |sample, idx| {
        // 再次计算分数用于显示（与排序键相同）。
        const computed_score = score(sample);
        std.debug.print(
            "  {d:>2}. {s: <12} latency={d}ms payload={d}B score={d:.2}\n",
            .{ idx + 1, sample.endpoint, sample.duration_ms, sample.payload_bytes, computed_score },
        );
    }
}
