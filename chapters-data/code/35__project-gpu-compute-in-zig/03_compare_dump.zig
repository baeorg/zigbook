// Utility to compare two float32 binary dumps.
// 工具函数 到 compare 两个 float32 binary dumps.
//
// The files are expected to be raw little-endian 32-bit float arrays. The
// 文件 are expected 到 be raw little-endian 32-bit float arrays.
// program prints the number of mismatched lanes (based on absolute tolerance)
// program prints 数字 的 mismatched lanes (基于 absolute tolerance)
// and highlights the first few differences for quick diagnostics.
// 和 highlights 首先 few differences 用于 quick diagnostics.

const std = @import("std");

// / Maximum number of mismatched differences to display in diagnostic output
// / Maximum 数字 的 mismatched differences 到 显示 在 diagnostic 输出
const max_preview = 5;

pub fn main() !void {
    // Initialize allocator with leak detection for development builds
    // Initialize allocator 使用 leak detection 用于 development builds
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer switch (gpa.deinit()) {
        .ok => {},
        .leak => std.log.warn("compare_dump leaked memory", .{}),
    };
    const allocator = gpa.allocator();

    // Parse command-line arguments expecting exactly two file paths
    // Parse command-line arguments expecting exactly 两个 文件 路径
    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();
    _ = args.next(); // Skip program name

    const expected_path = args.next() orelse return usageError();
    const actual_path = args.next() orelse return usageError();
    if (args.next()) |_| return usageError(); // Reject extra arguments

    // Load both binary dumps into memory for comparison
    // Load both binary dumps into 内存 用于 comparison
    const expected_bytes = try readAll(allocator, expected_path);
    defer allocator.free(expected_bytes);

    const actual_bytes = try readAll(allocator, actual_path);
    defer allocator.free(actual_bytes);

    // Reinterpret raw bytes as f32 slices for element-wise comparison
    // Reinterpret raw bytes 作为 f32 slices 用于 element-wise comparison
    const expected = std.mem.bytesAsSlice(f32, expected_bytes);
    const actual = std.mem.bytesAsSlice(f32, actual_bytes);

    // Early exit if array lengths differ
    // Early 退出 如果 数组 lengths differ
    if (expected.len != actual.len) {
        std.debug.print(
            "length mismatch: expected {d} elements, actual {d} elements\n",
            .{ expected.len, actual.len },
        );
        return;
    }

    // Track total mismatches and collect first few for detailed reporting
    // Track total mismatches 和 collect 首先 few 用于 detailed reporting
    var mismatches: usize = 0;
    var first_few: [max_preview]?Diff = .{null} ** max_preview;

    // Compare each lane using floating-point tolerance to account for minor precision differences
    // Compare 每个 lane 使用 floating-point tolerance 到 account 用于 minor precision differences
    for (expected, actual, 0..) |lhs, rhs, idx| {
        if (!std.math.approxEqAbs(f32, lhs, rhs, 1e-6)) {
            // Store first N differences for diagnostic display
            // Store 首先 N differences 用于 diagnostic 显示
            if (mismatches < max_preview) {
                first_few[mismatches] = Diff{ .index = idx, .expected = lhs, .actual = rhs };
            }
            mismatches += 1;
        }
    }

    // Print summary of comparison results
    // 打印 summary 的 comparison results
    std.debug.print("mismatched lanes: {d}\n", .{mismatches});
    
    // Display detailed information for first few mismatches to aid debugging
    // 显示 detailed 信息 用于 首先 few mismatches 到 aid debugging
    for (first_few) |maybe_diff| {
        if (maybe_diff) |diff| {
            std.debug.print(
                "  lane {d}: expected={d:.6} actual={d:.6}\n",
                .{ diff.index, diff.expected, diff.actual },
            );
        }
    }
}

// / Prints usage information and returns an error when invocation is invalid
// / Prints 使用说明 和 返回一个错误 当 invocation is 无效
fn usageError() !void {
    std.debug.print("usage: compare_dump <expected.bin> <actual.bin>\n", .{});
    return error.InvalidInvocation;
}

// / Reads entire file contents into allocated memory with a 64 MiB size limit
// / Reads entire 文件 contents into allocated 内存 使用 一个 64 MiB size limit
fn readAll(allocator: std.mem.Allocator, path: []const u8) ![]u8 {
    var file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
    return try file.readToEndAlloc(allocator, 1 << 26);
}

// / Captures a single floating-point mismatch with its location and values
// / Captures 一个 single floating-point mismatch 使用 its location 和 值
const Diff = struct {
    index: usize,
    expected: f32,
    actual: f32,
};
