// 向量平方内核的项目主机管线。
//
// 此程序演示了与 `squareVector` SPIR-V 内核配对的 CPU 编排。
// 它准备输入数据，规划调度，
// 验证编译后的着色器模块，并运行镜像 GPU 算法的 CPU 回退。
// 当通过 `--emit-binary` 请求时，它还将 CPU
// 输出写入 `out/reference.bin`，以便外部 GPU 运行可以进行逐位比较。

const std = @import("std");

//  必须与 01_vector_square_kernel.zig 中的 `lane_capacity` 匹配。
const lane_capacity: u32 = 1024;
const default_problem_len: u32 = 1000;
const workgroup_size: u32 = 64;
const spirv_path = "kernels/vector_square.spv";
const gpu_dump_path = "out/gpu_result.bin";
const cpu_dump_path = "out/reference.bin";

//  封装了 GPU 工作组调度几何体，考虑了填充
//  当总工作负载不能均匀地划分为工作组边界时。
const DispatchPlan = struct {
    workgroup_size: u32,
    group_count: u32,
    //  包括填充在内的总调用次数，以填充完整的工作组
    padded_invocations: u32,
    //  最后一个工作组中未使用的通道数量
    tail: u32,
};

//  跟踪一个经过验证的 SPIR-V 模块及其文件系统路径，用于诊断。
const ModuleInfo = struct {
    path: []const u8,
    bytes: []u8,
};

pub fn main() !void {
    // 为开发构建初始化带有泄漏检测的分配器
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer switch (gpa.deinit()) {
        .ok => {},
        .leak => std.log.err("general-purpose allocator detected a leak", .{}),
    };
    const allocator = gpa.allocator();

    // 解析命令行参数以获取可选标志
    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();
    _ = args.next(); // 跳过程序名

    var emit_binary = false;
    var logical_len: u32 = default_problem_len;

    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--emit-binary")) {
            emit_binary = true;
        } else if (std.mem.eql(u8, arg, "--length")) {
            const value = args.next() orelse return error.MissingLengthValue;
            logical_len = try std.fmt.parseInt(u32, value, 10);
        } else {
            return error.UnknownFlag;
        }
    }

    // 钳制用户提供的长度，以防止内核中的缓冲区溢出
    if (logical_len == 0 or logical_len > lane_capacity) {
        std.log.warn("clamping problem length to lane capacity ({d})", .{lane_capacity});
        logical_len = @min(lane_capacity, logical_len);
        if (logical_len == 0) logical_len = @min(lane_capacity, default_problem_len);
    }

    // 计算处理这么多元素需要多少个工作组
    const plan = computeDispatch(logical_len, workgroup_size);
    std.debug.print(
        "launch plan: {d} groups × {d} lanes => {d} invocations (tail {d})\n",
        .{ plan.group_count, plan.workgroup_size, plan.padded_invocations, plan.tail },
    );

    // 使用确定性 PRNG，以便在不同环境中进行可重现的测试运行
    var prng = std.Random.DefaultPrng.init(0xBEEFFACE);
    const random = prng.random();

    // 生成具有可预测模式和随机噪声的输入数据
    var input = try allocator.alloc(f32, logical_len);
    defer allocator.free(input);
    for (input, 0..input.len) |*slot, idx| {
        const base: f32 = @floatFromInt(idx);
        slot.* = base * 0.5 + random.float(f32);
    }

    // 执行 CPU 参考实现以生成预期结果
    var cpu_output = try allocator.alloc(f32, logical_len);
    defer allocator.free(cpu_output);
    runCpuFallback(input, cpu_output);

    // 计算简单的校验和以进行快速健全性验证
    const checksum = checksumSlice(cpu_output);
    std.debug.print("cpu fallback checksum: {d:.6}\n", .{checksum});

    // 尝试加载和验证已编译的 SPIR-V 着色器模块
    const module = try loadSpirvIfPresent(allocator, spirv_path);
    defer if (module) |info| allocator.free(info.bytes);

    if (module) |info| {
        std.debug.print(
            "gpu module: {s} ({d} bytes, header ok)\n",
            .{ info.path, info.bytes.len },
        );
    } else {
        std.debug.print(
            "gpu module: missing ({s}); run kernel build command to generate it\n",
            .{spirv_path},
        );
    }

    // 检查 GPU 执行是否捕获了用于比较的输出
    const maybe_gpu_dump = try loadBinaryIfPresent(allocator, gpu_dump_path);
    defer if (maybe_gpu_dump) |blob| allocator.free(blob);

    if (maybe_gpu_dump) |blob| {
        // 将 GPU 结果与 CPU 参考逐通道比较
        const mismatches = compareF32Slices(cpu_output, blob);
        std.debug.print(
            "gpu capture diff: {d} mismatched lanes\n",
            .{mismatches},
        );
    } else {
        std.debug.print(
            "gpu capture diff: skipped (no {s} file found)\n",
            .{gpu_dump_path},
        );
    }

    // 显示前几个通道以供手动检查
    const sample_count = @min(input.len, 6);
    for (input[0..sample_count], cpu_output[0..sample_count], 0..) |original, squared, idx| {
        std.debug.print(
            "lane {d:>3}: in={d:.5} out={d:.5}\n",
            .{ idx, original, squared },
        );
    }

    // 如果请求，写入参考转储以供外部 GPU 验证工具使用
    if (emit_binary) {
        try emitCpuDump(cpu_output);
        std.debug.print("cpu reference written to {s}\n", .{cpu_dump_path});
    }
}

// / 通过向上取整到完整工作组来计算调度几何体。
// / 返回组数、总填充调用次数和未使用的尾部通道数。
fn computeDispatch(total_items: u32, group_size: u32) DispatchPlan {
    std.debug.assert(group_size > 0);
    // 向上取整以确保所有项目都被覆盖
    const groups = std.math.divCeil(u32, total_items, group_size) catch unreachable;
    const padded = groups * group_size;
    return .{
        .workgroup_size = group_size,
        .group_count = groups,
        .padded_invocations = padded,
        .tail = padded - total_items,
    };
}

// / 在 CPU 上执行平方操作，镜像 GPU 内核逻辑。
// / 每个输出元素都是其相应输入的平方。
fn runCpuFallback(input: []const f32, output: []f32) void {
    std.debug.assert(input.len == output.len);
    for (input, output) |value, *slot| {
        slot.* = value * value;
    }
}

// / 以双精度计算所有 f32 值的简单总和，以供观察。
fn checksumSlice(values: []const f32) f64 {
    var total: f64 = 0.0;
    for (values) |value| {
        total += @as(f64, @floatCast(value));
    }
    return total;
}

//  尝试从磁盘读取和验证 SPIR-V 二进制模块。
//  如果文件不存在则返回 null；验证魔术数字 (0x07230203)。
fn loadSpirvIfPresent(allocator: std.mem.Allocator, path: []const u8) !?ModuleInfo {
    var file = std.fs.cwd().openFile(path, .{}) catch |err| switch (err) {
        error.FileNotFound => return null,
        else => return err,
    };
    defer file.close();

    const bytes = try file.readToEndAlloc(allocator, 1 << 20);
    errdefer allocator.free(bytes);

    // 验证 SPIR-V 头的最小大小
    if (bytes.len < 4) return error.SpirvTooSmall;
    // 检查小端序魔术数字
    const magic = std.mem.readInt(u32, bytes[0..4], .little);
    if (magic != 0x0723_0203) return error.InvalidSpirvMagic;

    return ModuleInfo{ .path = path, .bytes = bytes };
}

//  如果文件存在，则加载原始二进制数据；如果文件丢失，则返回 null。
fn loadBinaryIfPresent(allocator: std.mem.Allocator, path: []const u8) !?[]u8 {
    var file = std.fs.cwd().openFile(path, .{}) catch |err| switch (err) {
        error.FileNotFound => return null,
        else => return err,
    };
    defer file.close();
    const bytes = try file.readToEndAlloc(allocator, 1 << 24);
    return bytes;
}

//  在 1e-6 容差范围内比较两个 f32 切片的近似相等性。
//  返回不匹配通道的数量；如果大小不同，则返回 expected.len。
fn compareF32Slices(expected: []const f32, blob_bytes: []const u8) usize {
    // 确保 blob 大小与 f32 边界对齐
    if (blob_bytes.len % @sizeOf(f32) != 0) return expected.len;
    const actual = std.mem.bytesAsSlice(f32, blob_bytes);
    if (actual.len != expected.len) return expected.len;

    var mismatches: usize = 0;
    for (expected, actual) |lhs, rhs| {
        // 使用浮点容差以考虑微小的 GPU 精度差异
        if (!std.math.approxEqAbs(f32, lhs, rhs, 1e-6)) {
            mismatches += 1;
        }
    }
    return mismatches;
}

// / 将 CPU 计算的 f32 数组作为原始字节写入磁盘，以供外部比较工具使用。
fn emitCpuDump(values: []const f32) !void {
    // 确保输出目录存在后再写入
    try std.fs.cwd().makePath("out");
    var file = try std.fs.cwd().createFile(cpu_dump_path, .{ .truncate = true });
    defer file.close();
    // 将 f32 切片转换为原始字节以进行二进制序列化
    const bytes = std.mem.sliceAsBytes(values);
    try file.writeAll(bytes);
}
