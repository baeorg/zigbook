// 导入标准库以进行目标查询和打印
const std = @import("std");
// 导入内置模块以访问编译时主机目标信息
const builtin = @import("builtin");

// / 演示目标发现和跨平台元数据检查的入口点。
// / 此示例展示了如何内省主机编译目标以及解析
// / 假设的交叉编译目标，而无需实际构建它们。
pub fn main() void {
    // 通过访问 builtin.target 打印主机目标三元组（架构-操作系统-ABI）
    // 这显示了 Zig 当前正在为其编译的平台
    std.debug.print(
        "host triple: {s}-{s}-{s}\n",
        .{
            @tagName(builtin.target.cpu.arch),
            @tagName(builtin.target.os.tag),
            @tagName(builtin.target.abi),
        },
    );

    // 显示主机目标的指针宽度
    // @bitSizeOf(usize) 返回当前平台指针的位大小
    std.debug.print("pointer width: {d} bits\n", .{@bitSizeOf(usize)});

    // 从目标三元组字符串解析 WASI 目标查询
    // 这演示了如何以编程方式检查交叉编译目标
    const wasm_query = std.Target.Query.parse(.{ .arch_os_abi = "wasm32-wasi" }) catch unreachable;
    describeQuery("wasm32-wasi", wasm_query);

    // 解析 Windows 目标查询以显示另一个交叉编译场景
    // 三元组格式如下：架构-操作系统-ABI
    const windows_query = std.Target.Query.parse(.{ .arch_os_abi = "x86_64-windows-gnu" }) catch unreachable;
    describeQuery("x86_64-windows-gnu", windows_query);

    // 打印主机目标是否配置为单线程执行
    // 此编译时常量影响运行时库行为
    std.debug.print("single-threaded: {}\n", .{builtin.single_threaded});
}

//  打印给定目标查询的已解析架构、操作系统和 ABI。
//  此帮助程序演示了如何提取和显示目标元数据，使用
//  当查询未指定某些字段时，将主机目标用作回退。
fn describeQuery(label: []const u8, query: std.Target.Query) void {
    std.debug.print(
        "query {s}: arch={s} os={s} abi={s}\n",
        .{
            label,
            // 如果查询未指定，则回退到主机架构
            @tagName((query.cpu_arch orelse builtin.target.cpu.arch)),
            // 如果查询未指定，则回退到主机操作系统
            @tagName((query.os_tag orelse builtin.target.os.tag)),
            // 如果查询未指定，则回退到主机 ABI
            @tagName((query.abi orelse builtin.target.abi)),
        },
    );
}
