// ! GPU Kernel: Coordinate Capture
// ! GPU Kernel: Coordinate 捕获
//!
// ! This module demonstrates a minimal SPIR-V compute kernel that captures GPU dispatch
// ! 此 module 演示 一个 最小化 SPIR-V compute kernel 该 captures GPU dispatch
// ! coordinates into a storage buffer. It shows how to use Zig's GPU-specific builtins
// ! coordinates into 一个 storage 缓冲区. It shows how 到 use Zig's GPU-specific builtins
// ! and address space annotations to write kernels that compile to SPIR-V.
// ! 和 address space annotations 到 写入 kernels 该 编译 到 SPIR-V.

const builtin = @import("builtin");

// / Represents GPU dispatch coordinates for a single invocation
// / Represents GPU dispatch coordinates 用于 一个 single invocation
/// 
// / Uses `extern` layout to guarantee memory layout matches host-side expectations,
// / 使用 `extern` layout 到 guarantee 内存 layout matches host-side expectations,
// / ensuring the kernel's output can be safely interpreted by CPU code reading the buffer.
// / ensuring kernel's 输出 can be safely interpreted 通过 CPU 代码 reading 缓冲区.
const Coordinates = extern struct {
    // / Work group ID (which group this invocation belongs to)
    // / Work group ID (which group 此 invocation belongs 到)
    group: u32,
    // / Work group size (number of invocations per group in this dimension)
    // / Work group size (数字 的 invocations per group 在 此 dimension)
    group_size: u32,
    // / Local invocation ID within the work group (0 to group_size-1)
    // / Local invocation ID within work group (0 到 group_size-1)
    local: u32,
    // / Global linear ID across all invocations (group * group_size + local)
    // / Global linear ID across 所有 invocations (group * group_size + local)
    linear: u32,
};

// / GPU kernel entry point that captures dispatch coordinates
// / GPU kernel 程序入口点 该 captures dispatch coordinates
///
// / This function must be exported so the SPIR-V compiler generates an entry point.
// / 此 函数 must be exported so SPIR-V compiler generates 一个 程序入口点.
// / The `callconv(.kernel)` calling convention tells Zig to emit GPU-specific function
// / `callconv(.kernel)` calling convention tells Zig 到 emit GPU-specific 函数
// / attributes and handle parameter passing according to compute shader ABI.
// / attributes 和 处理 parameter passing 根据 compute shader ABI.
///
/// Parameters:
// /   - out: Pointer to storage buffer where coordinates will be written.
// / - out: Pointer 到 storage 缓冲区 where coordinates will be written.
// /          The `.storage_buffer` address space annotation ensures proper
// / `.storage_buffer` address space annotation 确保 proper
// /          memory access patterns for device-visible GPU memory.
// / 内存 access patterns 用于 device-visible GPU 内存.
pub export fn captureCoordinates(out: *addrspace(.storage_buffer) Coordinates) callconv(.kernel) void {
    // Query the work group ID in the X dimension (first dimension)
    // Query work group ID 在 X dimension (首先 dimension)
    // @workGroupId is a GPU-specific builtin that returns the current work group's coordinate
    // @workGroupId is 一个 GPU-specific 内置 该 返回 当前 work group's coordinate
    const group = @workGroupId(0);
    
    // Query the work group size (how many invocations per group in this dimension)
    // Query work group size (how many invocations per group 在 此 dimension)
    // This is set at dispatch time by the host and queried here for completeness
    // 此 is set 在 dispatch time 通过 host 和 queried here 用于 completeness
    const group_size = @workGroupSize(0);
    
    // Query the local invocation ID within this work group (0 to group_size-1)
    // Query local invocation ID within 此 work group (0 到 group_size-1)
    // @workItemId is the per-work-group thread index
    // @workItemId is per-work-group thread 索引
    const local = @workItemId(0);
    
    // Calculate global linear index across all invocations
    // Calculate global linear 索引 across 所有 invocations
    // This formula converts 2D coordinates (group, local) to a flat 1D index
    // 此 formula converts 2D coordinates (group, local) 到 一个 flat 1D 索引
    const linear = group * group_size + local;

    // Write all captured coordinates to the output buffer
    // 写入 所有 captured coordinates 到 输出 缓冲区
    // The GPU will ensure this write is visible to the host after synchronization
    // GPU will 确保 此 写入 is visible 到 host after synchronization
    out.* = .{
        .group = group,
        .group_size = group_size,
        .local = local,
        .linear = linear,
    };
}

// Compile-time validation to ensure this module is only compiled for SPIR-V targets
// 编译-time validation 到 确保 此 module is only compiled 用于 SPIR-V targets
// This prevents accidental compilation for CPU architectures where GPU builtins are unavailable
// 此 prevents accidental compilation 用于 CPU architectures where GPU builtins are unavailable
comptime {
    switch (builtin.target.cpu.arch) {
        // Accept both 32-bit and 64-bit SPIR-V architectures
        // Accept both 32-bit 和 64-bit SPIR-V architectures
        .spirv32, .spirv64 => {},
        // Reject all other architectures with a helpful error message
        // Reject 所有 other architectures 使用 一个 helpful 错误 message
        else => @compileError("captureCoordinates must be compiled with a SPIR-V target, e.g. -target spirv32-vulkan-none"),
    }
}
