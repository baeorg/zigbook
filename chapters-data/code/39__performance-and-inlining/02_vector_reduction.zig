const std = @import("std");

// Number of parallel operations per vector
// 数字 的 parallel operations per vector
const lanes = 4;
// Vector type that processes 4 f32 values simultaneously using SIMD
// Vector 类型 该 processes 4 f32 值 simultaneously 使用 SIMD
const Vec = @Vector(lanes, f32);

// / Loads 4 consecutive f32 values from a slice into a SIMD vector.
// / Loads 4 consecutive f32 值 从 一个 切片 into 一个 SIMD vector.
// / The caller must ensure that start + 3 is within bounds.
// / caller must 确保 该 start + 3 is within bounds.
fn loadVec(slice: []const f32, start: usize) Vec {
    return .{
        slice[start + 0],
        slice[start + 1],
        slice[start + 2],
        slice[start + 3],
    };
}

// / Computes the dot product of two f32 slices using scalar operations.
// / Computes dot product 的 两个 f32 slices 使用 scalar operations.
// / This is the baseline implementation that processes one element at a time.
// / 此 is baseline implementation 该 processes 一个 element 在 一个 time.
fn dotScalar(values_a: []const f32, values_b: []const f32) f32 {
    std.debug.assert(values_a.len == values_b.len);
    var sum: f32 = 0.0;
    // Multiply corresponding elements and accumulate the sum
    // Multiply 对应的 elements 和 accumulate sum
    for (values_a, values_b) |a, b| {
        sum += a * b;
    }
    return sum;
}

// / Computes the dot product using SIMD vectorization for improved performance.
// / Computes dot product 使用 SIMD vectorization 用于 improved performance.
// / Processes 4 elements at a time, then reduces the vector accumulator to a scalar.
// / Processes 4 elements 在 一个 time, 那么 reduces vector accumulator 到 一个 scalar.
// / Requires that the input length is a multiple of the lane count (4).
// / Requires 该 输入 length is 一个 multiple 的 lane count (4).
fn dotVectorized(values_a: []const f32, values_b: []const f32) f32 {
    std.debug.assert(values_a.len == values_b.len);
    std.debug.assert(values_a.len % lanes == 0);

    // Initialize accumulator vector with zeros
    // Initialize accumulator vector 使用 zeros
    var accum: Vec = @splat(0.0);
    var index: usize = 0;
    // Process 4 elements per iteration using SIMD
    // Process 4 elements per iteration 使用 SIMD
    while (index < values_a.len) : (index += lanes) {
        const lhs = loadVec(values_a, index);
        const rhs = loadVec(values_b, index);
        // Perform element-wise multiplication and add to accumulator
        // 执行 element-wise multiplication 和 add 到 accumulator
        accum += lhs * rhs;
    }

    // Sum all lanes of the accumulator vector into a single scalar value
    // Sum 所有 lanes 的 accumulator vector into 一个 single scalar 值
    return @reduce(.Add, accum);
}

// Verifies that the vectorized implementation produces the same result as the scalar version.
// Verifies 该 vectorized implementation produces same result 作为 scalar version.
test "vectorized dot product matches scalar" {
    const lhs = [_]f32{ 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0 };
    const rhs = [_]f32{ 8.0, 7.0, 6.0, 5.0, 4.0, 3.0, 2.0, 1.0 };
    const scalar = dotScalar(&lhs, &rhs);
    const vector = dotVectorized(&lhs, &rhs);
    // Allow small floating-point error tolerance
    // Allow small floating-point 错误 tolerance
    try std.testing.expectApproxEqAbs(scalar, vector, 0.0001);
}
