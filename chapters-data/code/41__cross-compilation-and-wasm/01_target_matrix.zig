// Import standard library for target querying and printing
// 导入 标准库 用于 target querying 和 printing
const std = @import("std");
// Import builtin module to access compile-time host target information
// 导入 内置 module 以访问 编译-time host target 信息
const builtin = @import("builtin");

// / Entry point that demonstrates target discovery and cross-platform metadata inspection.
// / 程序入口点 该 演示 target discovery 和 cross-platform metadata inspection.
// / This example shows how to introspect both the host compilation target and parse
// / 此 示例 shows how 到 introspect both host compilation target 和 parse
// / hypothetical cross-compilation targets without actually building for them.
// / hypothetical cross-compilation targets without actually building 用于 them.
pub fn main() void {
    // Print the host target triple (architecture-OS-ABI) by accessing builtin.target
    // 打印 host target triple (architecture-OS-ABI) 通过 accessing 内置.target
    // This shows the platform Zig is currently compiling for
    // 此 shows platform Zig is currently compiling 用于
    std.debug.print(
        "host triple: {s}-{s}-{s}\n",
        .{
            @tagName(builtin.target.cpu.arch),
            @tagName(builtin.target.os.tag),
            @tagName(builtin.target.abi),
        },
    );

    // Display the pointer width for the host target
    // 显示 pointer width 用于 host target
    // @bitSizeOf(usize) returns the size in bits of a pointer on the current platform
    // @bitSizeOf(usize) 返回 size 在 bits 的 一个 pointer 在 当前 platform
    std.debug.print("pointer width: {d} bits\n", .{@bitSizeOf(usize)});

    // Parse a WASI target query from a target triple string
    // Parse 一个 WASI target query 从 一个 target triple string
    // This demonstrates how to inspect cross-compilation targets programmatically
    // 此 演示 how 到 inspect cross-compilation targets programmatically
    const wasm_query = std.Target.Query.parse(.{ .arch_os_abi = "wasm32-wasi" }) catch unreachable;
    describeQuery("wasm32-wasi", wasm_query);

    // Parse a Windows target query to show another cross-compilation scenario
    // Parse 一个 Windows target query 到 show another cross-compilation scenario
    // The triple format follows: architecture-OS-ABI
    // triple format follows: architecture-OS-ABI
    const windows_query = std.Target.Query.parse(.{ .arch_os_abi = "x86_64-windows-gnu" }) catch unreachable;
    describeQuery("x86_64-windows-gnu", windows_query);

    // Print whether the host target is configured for single-threaded execution
    // 打印 whether host target is configured 用于 single-threaded execution
    // This compile-time constant affects runtime library behavior
    // 此 编译-time constant affects runtime 库 behavior
    std.debug.print("single-threaded: {}\n", .{builtin.single_threaded});
}

// / Prints the resolved architecture, OS, and ABI for a given target query.
// / Prints resolved architecture, OS, 和 ABI 用于 一个 given target query.
// / This helper demonstrates how to extract and display target metadata, using
// / 此 helper 演示 how 到 extract 和 显示 target metadata, 使用
// / the host target as a fallback when the query doesn't specify certain fields.
// / host target 作为 一个 fallback 当 query doesn't specify certain fields.
fn describeQuery(label: []const u8, query: std.Target.Query) void {
    std.debug.print(
        "query {s}: arch={s} os={s} abi={s}\n",
        .{
            label,
            // Fall back to host architecture if query doesn't specify one
            // Fall back 到 host architecture 如果 query doesn't specify 一个
            @tagName((query.cpu_arch orelse builtin.target.cpu.arch)),
            // Fall back to host OS if query doesn't specify one
            // Fall back 到 host OS 如果 query doesn't specify 一个
            @tagName((query.os_tag orelse builtin.target.os.tag)),
            // Fall back to host ABI if query doesn't specify one
            // Fall back 到 host ABI 如果 query doesn't specify 一个
            @tagName((query.abi orelse builtin.target.abi)),
        },
    );
}
