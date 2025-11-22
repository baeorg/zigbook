// 比较两个 float32 二进制转储的工具。
//
// 这些文件预计是原始的小端序 32 位浮点数组。该
// 程序打印不匹配通道的数量（基于绝对容差），
// 并高亮显示前几个差异以进行快速诊断。

const std = @import("std");

// / 在诊断输出中显示的最大不匹配差异数量
const max_preview = 5;

pub fn main() !void {
    // 为开发构建初始化带有泄漏检测的分配器
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer switch (gpa.deinit()) {
        .ok => {},
        .leak => std.log.warn("compare_dump leaked memory", .{}),
    };
    const allocator = gpa.allocator();

    // 解析命令行参数，期望精确地有两个文件路径
    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();
    _ = args.next(); // 跳过程序名

    const expected_path = args.next() orelse return usageError();
    const actual_path = args.next() orelse return usageError();
    if (args.next()) |_| return usageError(); // 拒绝额外参数

    // 将两个二进制转储加载到内存中进行比较
    const expected_bytes = try readAll(allocator, expected_path);
    defer allocator.free(expected_bytes);

    const actual_bytes = try readAll(allocator, actual_path);
    defer allocator.free(actual_bytes);

    // 将原始字节重新解释为 f32 切片以进行逐元素比较
    const expected = std.mem.bytesAsSlice(f32, expected_bytes);
    const actual = std.mem.bytesAsSlice(f32, actual_bytes);

    // 如果数组长度不同，则提前退出
    if (expected.len != actual.len) {
        std.debug.print(
            "length mismatch: expected {d} elements, actual {d} elements\n",
            .{ expected.len, actual.len },
        );
        return;
    }

    // 跟踪总不匹配项并收集前几个以进行详细报告
    var mismatches: usize = 0;
    var first_few: [max_preview]?Diff = .{null} ** max_preview;

    // 使用浮点容差比较每个通道，以考虑微小的精度差异
    for (expected, actual, 0..) |lhs, rhs, idx| {
        if (!std.math.approxEqAbs(f32, lhs, rhs, 1e-6)) {
            // 存储前 N 个差异以进行诊断显示
            if (mismatches < max_preview) {
                first_few[mismatches] = Diff{ .index = idx, .expected = lhs, .actual = rhs };
            }
            mismatches += 1;
        }
    }

    // 打印比较结果摘要
    std.debug.print("mismatched lanes: {d}\n", .{mismatches});

    // 显示前几个不匹配项的详细信息以帮助调试
    for (first_few) |maybe_diff| {
        if (maybe_diff) |diff| {
            std.debug.print(
                "  lane {d}: expected={d:.6} actual={d:.6}\n",
                .{ diff.index, diff.expected, diff.actual },
            );
        }
    }
}

// / 打印用法信息并在调用无效时返回错误
fn usageError() !void {
    std.debug.print("usage: compare_dump <expected.bin> <actual.bin>\n", .{});
    return error.InvalidInvocation;
}

// / 将整个文件内容读取到分配的内存中，大小限制为 64 MiB
fn readAll(allocator: std.mem.Allocator, path: []const u8) ![]u8 {
    var file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
    return try file.readToEndAlloc(allocator, 1 << 26);
}

// / 捕获单个浮点不匹配及其位置和值
const Diff = struct {
    index: usize,
    expected: f32,
    actual: f32,
};
