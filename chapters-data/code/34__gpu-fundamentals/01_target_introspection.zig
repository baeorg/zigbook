const std = @import("std");
const builtin = @import("builtin");

pub fn main() !void {
    // Query the compile-time target information to inspect the environment
    // 查询编译时目标信息以检查环境
    // this binary is being compiled for (host or cross-compilation target)
    // 此二进制文件正在为其编译（主机或交叉编译目标）
    const target = builtin.target;

    // Display basic target information: CPU architecture, OS, and object format
    // 显示基本目标信息：CPU架构、操作系统和对象格式
    std.debug.print("host architecture: {s}\n", .{@tagName(target.cpu.arch)});
    std.debug.print("host operating system: {s}\n", .{@tagName(target.os.tag)});
    std.debug.print("default object format: {s}\n", .{@tagName(target.ofmt)});

    // Check if we're compiling for a GPU backend by examining the target CPU architecture.
    // 通过检查目标 CPU 架构，检查我们是否正在为 GPU 后端编译。
    // GPU architectures include AMD GCN, NVIDIA PTX variants, and SPIR-V targets.
    // GPU 架构包括 AMD GCN、NVIDIA PTX 变体和 SPIR-V 目标。
    const is_gpu_backend = switch (target.cpu.arch) {
        .amdgcn, .nvptx, .nvptx64, .spirv32, .spirv64 => true,
        else => false,
    };
    std.debug.print("compiling as GPU backend: {}\n", .{is_gpu_backend});

    // Import address space types for querying GPU-specific memory capabilities
    // 导入地址空间类型以查询 GPU 特定的内存功能
    const AddressSpace = std.builtin.AddressSpace;
    const Context = AddressSpace.Context;

    // Query whether the target supports GPU-specific address spaces:
    // 查询目标是否支持 GPU 特定的地址空间：
    // - shared: memory shared within a workgroup/threadblock
    // - shared: 工作组/线程块内共享的内存
    // - constant: read-only memory optimized for uniform access across threads
    // - constant: 为跨线程统一访问优化的只读内存
    const shared_ok = target.cpu.supportsAddressSpace(AddressSpace.shared, null);
    const constant_ok = target.cpu.supportsAddressSpace(AddressSpace.constant, Context.constant);

    std.debug.print("supports shared address space: {}\n", .{shared_ok});
    std.debug.print("supports constant address space: {}\n", .{constant_ok});

    // Construct a custom target query for SPIR-V 64-bit targeting Vulkan
    // 构造一个针对 Vulkan 的 SPIR-V 64 位自定义目标查询
    const gpa = std.heap.page_allocator;
    const query = std.Target.Query{
        .cpu_arch = .spirv64,
        .os_tag = .vulkan,
        .abi = .none,
    };

    // Convert the target query to a triple string (e.g., "spirv64-vulkan")
    // 将目标查询转换为三元组字符串（例如，“spirv64-vulkan”）
    const triple = try query.zigTriple(gpa);
    defer gpa.free(triple);
    std.debug.print("example SPIR-V triple: {s}\n", .{triple});
}
