//! SPIR-V 内核：逐元素向量平方
//!
// ! 该内核需要三个存储缓冲区：一个输入向量 (`in_values`)，一个
// ! 输出向量 (`out_values`)，以及一个描述符结构体 `Submission`，它
// ! 传递逻辑元素计数。每次调用都会将一个元素平方
// ! 并将结果写入 `out_values`。

const builtin = @import("builtin");

// / 内核将触及的最大元素数量。
pub const lane_capacity: u32 = 1024;

// / 主机和内核之间共享的提交头。
///
// / `extern` 布局确保结构与 Vulkan 或
/// WebGPU 描述符表创建的绑定匹配。
const Submission = extern struct {
    // / 主机请求的逻辑元素计数。
    len: u32,
    _padding: u32 = 0,
};

// / 内核预期的存储缓冲区布局。
const VectorPayload = extern struct {
    values: [lane_capacity]f32,
};

// / 将 `in_values` 的每个元素平方并将结果写入 `out_values`。
///
// / 内核是防御性编写的：它检查主机传递的逻辑长度
// / 和静态 `lane_capacity`，以避免在调度时出现越界写入，
// / 当调度线程数量超过所需时。
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

// 保护编译，使此文件仅在目标为 SPIR-V 时编译。
comptime {
    switch (builtin.target.cpu.arch) {
        .spirv32, .spirv64 => {},
        else => @compileError("squareVector must be compiled with a SPIR-V target, e.g. -target spirv32-vulkan-none"),
    }
}
