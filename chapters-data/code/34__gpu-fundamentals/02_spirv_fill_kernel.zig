// ! GPU内核：坐标捕获
//!
//! 此模块演示一个最小的SPIR-V计算内核，它将GPU调度坐标捕获到存储缓冲区中。
//! 它展示了如何使用Zig的GPU特定内置函数和地址空间注释来编写编译为SPIR-V的内核。

const builtin = @import("builtin");

/// 表示单个调用的GPU调度坐标
///
/// 使用`extern`布局来保证内存布局与主机端期望匹配，
/// 确保内核的输出可以被读取缓冲区的CPU代码安全解释。
const Coordinates = extern struct {
    // 工作组ID（此调用所属的组）
    group: u32,
    // 工作组大小（此维度中每组的调用数）
    group_size: u32,
    // 工作组内的本地调用ID（0到group_size-1）
    local: u32,
    // 所有调用的全局线性ID（group * group_size + local）
    linear: u32,
};

/// 捕获调度坐标的GPU内核入口点
///
/// 此函数必须被导出，以便SPIR-V编译器生成入口点。
/// `callconv(.kernel)`调用约定告诉Zig发出GPU特定函数属性，
/// 并根据计算着色器ABI处理参数传递。
///
/// 参数：
///   - out：指向将写入坐标的存储缓冲区的指针。
///          `.storage_buffer`地址空间注释确保适当的
///          设备可见GPU内存的内存访问模式。
pub export fn captureCoordinates(out: *addrspace(.storage_buffer) Coordinates) callconv(.kernel) void {
    // 查询X维度中的工作组ID（第一维度）
    // @workGroupId是GPU特定的内置函数，返回当前工作组的坐标
    const group = @workGroupId(0);

    // 查询工作组大小（此维度中每组的调用数）
    // 这在调度时由主机设置并在此处查询以保持完整性
    const group_size = @workGroupSize(0);

    // 查询此工作组内的本地调用ID（0到group_size-1）
    // @workItemId是每个工作组的线程索引
    const local = @workItemId(0);

    // 计算所有调用的全局线性索引
    // 此公式将2D坐标（group, local）转换为扁平1D索引
    const linear = group * group_size + local;

    // 将所有捕获的坐标写入输出缓冲区
    // GPU将确保此写入在同步后对主机可见
    out.* = .{
        .group = group,
        .group_size = group_size,
        .local = local,
        .linear = linear,
    };
}

// 编译时验证，确保此模块仅针对SPIR-V目标编译
// 这可以防止意外编译到GPU内置函数不可用的CPU架构
comptime {
    switch (builtin.target.cpu.arch) {
        // 接受32位和64位SPIR-V架构
        .spirv32, .spirv64 => {},
        // 使用有用的错误消息拒绝所有其他架构
        else => @compileError("captureCoordinates must be compiled with a SPIR-V target, e.g. -target spirv32-vulkan-none"),
    }
}
