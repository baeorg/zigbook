const std = @import("std");

// 每个向量的并行操作数
const lanes = 4;
// 处理4个f32值同时使用SIMD的向量类型
const Vec = @Vector(lanes, f32);

// 从切片加载4个连续的f32值到SIMD向量中。
// 调用者必须确保start + 3在边界内。
fn loadVec(slice: []const f32, start: usize) Vec {
    return .{
        slice[start + 0],
        slice[start + 1],
        slice[start + 2],
        slice[start + 3],
    };
}

// 使用标量操作计算两个f32切片的点积。
// 这是基线实现，一次处理一个元素。
fn dotScalar(values_a: []const f32, values_b: []const f32) f32 {
    std.debug.assert(values_a.len == values_b.len);
    var sum: f32 = 0.0;
    // 乘以对应元素并累积求和
    for (values_a, values_b) |a, b| {
        sum += a * b;
    }
    return sum;
}

// 使用SIMD向量化计算点积以提高性能。
// 一次处理4个元素，然后将向量累加器归约为标量。
// 要求输入长度是通道数（4）的倍数。
fn dotVectorized(values_a: []const f32, values_b: []const f32) f32 {
    std.debug.assert(values_a.len == values_b.len);
    std.debug.assert(values_a.len % lanes == 0);

    // 用零初始化累加器向量
    var accum: Vec = @splat(0.0);
    var index: usize = 0;
    // 每次迭代使用SIMD处理4个元素
    while (index < values_a.len) : (index += lanes) {
        const lhs = loadVec(values_a, index);
        const rhs = loadVec(values_b, index);
        // 执行按元素乘法并添加到累加器
        accum += lhs * rhs;
    }

    // 将累加器向量的所有通道求和为单个标量值
    return @reduce(.Add, accum);
}

// 验证向量化实现产生与标量版本相同的结果。
test "vectorized dot product matches scalar" {
    const lhs = [_]f32{ 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0 };
    const rhs = [_]f32{ 8.0, 7.0, 6.0, 5.0, 4.0, 3.0, 2.0, 1.0 };
    const scalar = dotScalar(&lhs, &rhs);
    const vector = dotVectorized(&lhs, &rhs);
    // 允许小的浮点误差容忍度
    try std.testing.expectApproxEqAbs(scalar, vector, 0.0001);
}
