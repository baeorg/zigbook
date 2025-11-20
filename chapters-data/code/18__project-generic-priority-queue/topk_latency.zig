// Import the Zig standard library for allocator, sorting, debugging, etc.
// 导入 Zig 标准库 用于 allocator, sorting, debugging, 等.
const std = @import("std");

const Order = std.math.Order;

// A single latency measurement for an endpoint.
// 一个 single latency measurement 用于 一个 endpoint.
// Fields:
// - endpoint: UTF-8 byte slice identifying the endpoint.
// - endpoint: UTF-8 byte 切片 identifying endpoint.
// - duration_ms: observed latency in milliseconds.
// - duration_ms: observed latency 在 milliseconds.
// - payload_bytes: size of the request/response payload in bytes.
// - payload_bytes: size 的 request/response 载荷 在 bytes.
const LatencySample = struct {
    endpoint: []const u8,
    duration_ms: u32,
    payload_bytes: u32,
};

// Compute a score for a latency sample.
// Compute 一个 score 用于 一个 latency sample.
// Higher scores represent more severe (worse) samples. The formula favors
// Higher scores represent more severe (worse) 样本. formula favors
// larger durations and applies a small penalty for larger payloads to reduce
// larger durations 和 applies 一个 small penalty 用于 larger payloads 到 reduce
// noisy high-latency large-payload samples.
// noisy high-latency large-载荷 样本.
//
// Returns an f64 so scores can be compared with fractional penalties.
// 返回 一个 f64 so scores can be compared 使用 fractional penalties.
fn score(sample: LatencySample) f64 {
    // Convert integers to floating point explicitly to avoid implicit casts.
    // Convert 整数 到 floating point explicitly 到 avoid implicit casts.
    // The penalty factor 0.005 was chosen empirically to be small.
    // penalty factor 0.005 was chosen empirically 到 be small.
    return @as(f64, @floatFromInt(sample.duration_ms)) - (@as(f64, @floatFromInt(sample.payload_bytes)) * 0.005);
}

// TopK is a compile-time generic producer that returns a fixed-capacity,
// TopK is 一个 编译-time 通用 producer 该 返回 一个 fixed-capacity,
// score-driven top-K tracker for items of type T.
// score-driven top-K tracker 用于 items 的 类型 T.
//
// Parameters:
// - T: the element type stored in the tracker.
// - T: element 类型 stored 在 tracker.
// - scoreFn: a compile-time function that maps T -> f64 used to rank elements.
// - scoreFn: 一个 编译-time 函数 该 maps T -> f64 used 到 rank elements.
fn TopK(comptime T: type, comptime scoreFn: fn (T) f64) type {
    const Error = error{InvalidLimit};

    // Comparator helpers used by the PriorityQueue and for sorting snapshots.
    // Comparator helpers used 通过 PriorityQueue 和 用于 sorting snapshots.
    const Comparators = struct {
        // Comparator used by the PriorityQueue. The first parameter is the
        // Comparator used 通过 PriorityQueue. 首先 parameter is
        // user-provided context (unused here), hence the underscore name.
        // user-provided context (unused here), hence underscore name.
        // Returns an Order (Less/Equal/Greater) based on the score function.
        // 返回 一个 Order (Less/Equal/Greater) 基于 score 函数.
        fn heap(_: void, a: T, b: T) Order {
            return std.math.order(scoreFn(a), scoreFn(b));
        }

        // Boolean comparator used by the heap sort to produce descending order.
        // Boolean comparator used 通过 堆 sort 到 produce descending order.
        // Returns true when `a` should come before `b` (i.e., a has higher score).
        // 返回 true 当 `一个` should come before `b` (i.e., 一个 has higher score).
        fn desc(_: void, a: T, b: T) bool {
            return scoreFn(a) > scoreFn(b);
        }
    };

    return struct {
        // A priority queue specialized for T using our heap comparator.
        // 一个 priority queue specialized 用于 T 使用 our 堆 comparator.
        const Heap = std.PriorityQueue(T, void, Comparators.heap);
        const Self = @This();

        heap: Heap,
        limit: usize,

        // Initialize a TopK tracker with the provided allocator and positive limit.
        // Initialize 一个 TopK tracker 使用 provided allocator 和 正数 limit.
        // Returns Error.InvalidLimit when limit == 0.
        // 返回 错误.InvalidLimit 当 limit == 0.
        pub fn init(allocator: std.mem.Allocator, limit: usize) Error!Self {
            if (limit == 0) return Error.InvalidLimit;
            return .{ .heap = Heap.init(allocator, {}), .limit = limit };
        }

        // Deinitialize the underlying heap and free its resources.
        // Deinitialize underlying 堆 和 释放 its resources.
        pub fn deinit(self: *Self) void {
            self.heap.deinit();
        }

        // Add a single value into the tracker. If adding causes the internal
        // Add 一个 single 值 into tracker. 如果 adding causes internal
        // count to exceed `limit`, the priority queue will evict the item it
        // count 到 exceed `limit`, priority queue will evict item it
        // considers lowest priority according to our comparator, keeping the
        // considers lowest priority 根据 our comparator, keeping
        // top-K scored items.
        pub fn add(self: *Self, value: T) !void {
            try self.heap.add(value);
            if (self.heap.count() > self.limit) {
                // Evict the lowest-priority element (as defined by Comparators.heap).
                // Evict lowest-priority element (作为 defined 通过 Comparators.堆).
                _ = self.heap.remove();
            }
        }

        // Add multiple values from a slice into the tracker.
        // Add multiple 值 从 一个 切片 into tracker.
        // This simply forwards each element to `add`.
        // 此 simply forwards 每个 element 到 `add`.
        pub fn addSlice(self: *Self, values: []const T) !void {
            for (values) |value| try self.add(value);
        }

        // Produce a snapshot of the current tracked items in descending score order.
        // Produce 一个 snapshot 的 当前 tracked items 在 descending score order.
        //
        // The snapshot allocates a new array via `allocator` and copies the
        // snapshot 分配 一个 新 数组 via `allocator` 和 copies
        // internal heap's item storage into it. The result is then sorted
        // internal 堆's item storage into it. result is 那么 sorted
        // descending (highest score first) using Comparators.desc.
        // descending (highest score 首先) 使用 Comparators.desc.
        //
        // Caller is responsible for freeing the returned slice.
        // Caller is responsible 用于 freeing returned 切片.
        pub fn snapshotDescending(self: *Self, allocator: std.mem.Allocator) ![]T {
            const count = self.heap.count();
            const out = try allocator.alloc(T, count);
            // Copy the underlying items buffer into the newly allocated array.
            // 复制 underlying items 缓冲区 into newly allocated 数组.
            // This creates an independent snapshot so we can sort without mutating the heap.
            // 此 creates 一个 independent snapshot so we can sort without mutating 堆.
            @memcpy(out, self.heap.items[0..count]);
            // Sort in-place so the highest-scored items appear first.
            // Sort 在-place so highest-scored items appear 首先.
            std.sort.heap(T, out, @as(void, {}), Comparators.desc);
            return out;
        }
    };
}

// Example program demonstrating TopK usage with LatencySample.
// 示例 program demonstrating TopK usage 使用 LatencySample.
pub fn main() !void {
    // Create a general-purpose allocator for example allocations.
    // 创建一个 general-purpose allocator 例如 allocations.
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Track the top 5 latency samples by computed score.
    // Track top 5 latency 样本 通过 computed score.
    var tracker = try TopK(LatencySample, score).init(allocator, 5);
    defer tracker.deinit();

    // Example samples. These are small, stack-allocated literal records.
    // 示例 样本. 这些 are small, 栈-allocated 字面量 records.
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

    // Bulk-add the sample slice into the tracker.
    // Bulk-add sample 切片 into tracker.
    try tracker.addSlice(&samples);

    // Capture the current top-K samples in descending order and print them.
    // 捕获 当前 top-K 样本 在 descending order 和 打印 them.
    const worst = try tracker.snapshotDescending(allocator);
    defer allocator.free(worst);

    std.debug.print("Top latency offenders (descending by score):\n", .{});
    for (worst, 0..) |sample, idx| {
        // Compute the score again for display purposes (identical to the ordering key).
        // Compute score again 用于 显示 purposes (identical 到 ordering key).
        const computed_score = score(sample);
        std.debug.print(
            "  {d:>2}. {s: <12} latency={d}ms payload={d}B score={d:.2}\n",
            .{ idx + 1, sample.endpoint, sample.duration_ms, sample.payload_bytes, computed_score },
        );
    }
}