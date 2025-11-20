//! SPIR-V Kernel: element-wise vector squaring
//!
// ! This kernel expects three storage buffers: an input vector (`in_values`), an
// ! 此 kernel expects 三个 storage buffers: 一个 输入 vector (`in_values`), 一个
// ! output vector (`out_values`), and a descriptor struct `Submission` that
// ! 输出 vector (`out_values`), 和 一个 descriptor struct `Submission` 该
// ! communicates the logical element count. Each invocation squares one element
// ! communicates logical element count. 每个 invocation squares 一个 element
// ! and writes the result back to `out_values`.
// ! 和 writes result back 到 `out_values`.

const builtin = @import("builtin");

// / Maximum number of elements the kernel will touch.
// / Maximum 数字 的 elements kernel will touch.
pub const lane_capacity: u32 = 1024;

// / Submission header shared between the host and the kernel.
// / Submission header shared between host 和 kernel.
///
// / The `extern` layout ensures the struct matches bindings created by Vulkan or
// / `extern` layout 确保 struct matches bindings created 通过 Vulkan 或
/// WebGPU descriptor tables.
const Submission = extern struct {
    // / Logical element count requested by the host.
    // / Logical element count requested 通过 host.
    len: u32,
    _padding: u32 = 0,
};

// / Storage buffer layout expected by the kernel.
// / Storage 缓冲区 layout expected 通过 kernel.
const VectorPayload = extern struct {
    values: [lane_capacity]f32,
};

// / Squares each element of `in_values` and writes the result to `out_values`.
// / Squares 每个 element 的 `in_values` 和 writes result 到 `out_values`.
///
// / The kernel is written defensively: it checks both the logical length passed
// / kernel is written defensively: it checks both logical length passed
// / by the host and the static `lane_capacity` to avoid out-of-bounds writes when
// / 通过 host 和 static `lane_capacity` 到 avoid out-的-bounds writes 当
// / dispatched with more threads than necessary.
// / dispatched 使用 more threads than necessary.
pub export fn squareVector(
    submission: *addrspace(.storage_buffer) const Submission,
    in_values: *addrspace(.storage_buffer) const VectorPayload,
    out_values: *addrspace(.storage_buffer) VectorPayload,
) callconv(.kernel) void {
    const group_index = @workGroupId(0);
    const group_width = @workGroupSize(0);
    const local_index = @workItemId(0);
    const linear = group_index * group_width + local_index;

    const logical_len = submission.len;
    if (linear >= logical_len or linear >= lane_capacity) return;

    const value = in_values.*.values[linear];
    out_values.*.values[linear] = value * value;
}

// Guard compilation so this file is only compiled when targeting SPIR-V.
// Guard compilation so 此 文件 is only compiled 当 targeting SPIR-V.
comptime {
    switch (builtin.target.cpu.arch) {
        .spirv32, .spirv64 => {},
        else => @compileError("squareVector must be compiled with a SPIR-V target, e.g. -target spirv32-vulkan-none"),
    }
}
