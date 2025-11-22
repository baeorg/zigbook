const std = @import("std");
const builtin = @import("builtin");

pub fn main() !void {
    // 设置一个通用分配器用于动态内存分配
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    // 检索传递给程序的所有命令行参数
    const argv = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, argv);

    // 显示编译期间使用的优化模式（Debug, ReleaseSafe, ReleaseFast, ReleaseSmall）
    std.debug.print("optimize-mode: {s}\n", .{@tagName(builtin.mode)});

    // 显示目标平台三元组（架构-操作系统-ABI）
    std.debug.print(
        "target-triple: {s}-{s}-{s}\n",
        .{
            @tagName(builtin.target.cpu.arch),
            @tagName(builtin.target.os.tag),
            @tagName(builtin.target.abi),
        },
    );

    // 显示程序是否以单线程模式编译
    std.debug.print("single-threaded: {}\n", .{builtin.single_threaded});

    // 检查是否提供了任何用户参数（argv[0] 是程序名本身）
    if (argv.len <= 1) {
        std.debug.print("user-args: <none>\n", .{});
        return;
    }

    // 打印所有用户提供的参数（跳过 argv[0] 处的程序名）
    std.debug.print("user-args:\n", .{});
    for (argv[1..], 0..) |arg, idx| {
        std.debug.print("  arg[{d}] = {s}\n", .{ idx, arg });
    }
}
