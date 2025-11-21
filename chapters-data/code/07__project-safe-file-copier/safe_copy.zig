const std = @import("std");

// 第7章 - 安全文件复制器（通过 std.fs.Dir.copyFile 实现原子操作）
//
// 一个极简的命令行工具，默认安全，拒绝覆盖已存在的目标文件，
// 除非提供 --force 参数。使用 std.fs.Dir.copyFile 实现，
// 该函数先写入临时文件，然后原子性地重命名到目标位置。
//
// 用法:
//   zig run safe_copy.zig -- <源文件> <目标文件>
//   zig run safe_copy.zig -- --force <源文件> <目标文件>

const Cli = struct {
    force: bool = false,
    src: []const u8 = &[_]u8{},
    dst: []const u8 = &[_]u8{},
};

fn printUsage() void {
    std.debug.print("usage: safe-copy [--force] <source> <dest>\n", .{});
}

fn parseArgs(allocator: std.mem.Allocator) !Cli {
    var cli: Cli = .{};
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len == 1 or (args.len == 2 and std.mem.eql(u8, args[1], "--help"))) {
        printUsage();
        std.process.exit(0);
    }

    var i: usize = 1;
    while (i < args.len and std.mem.startsWith(u8, args[i], "--")) : (i += 1) {
        const flag = args[i];
        if (std.mem.eql(u8, flag, "--force")) {
            cli.force = true;
        } else if (std.mem.eql(u8, flag, "--help")) {
            printUsage();
            std.process.exit(0);
        } else {
            std.debug.print("error: unknown flag '{s}'\n", .{flag});
            printUsage();
            std.process.exit(2);
        }
    }

    const remaining = args.len - i;
    if (remaining != 2) {
        std.debug.print("error: expected <source> and <dest>\n", .{});
        printUsage();
        std.process.exit(2);
    }

    // 复制路径，确保在释放参数后仍保持有效
    cli.src = try allocator.dupe(u8, args[i]);
    cli.dst = try allocator.dupe(u8, args[i + 1]);
    return cli;
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const cli = try parseArgs(allocator);

    const cwd = std.fs.cwd();

    // 验证源文件存在且为常规文件
    var src_file = cwd.openFile(cli.src, .{ .mode = .read_only }) catch {
        std.debug.print("error: unable to open source '{s}'\n", .{cli.src});
        std.process.exit(1);
    };
    defer src_file.close();

    const st = try src_file.stat();
    if (st.kind != .file) {
        std.debug.print("error: source is not a regular file\n", .{});
        std.process.exit(1);
    }

    // 遵循"默认安全"理念：除非使用 --force，否则拒绝覆盖
    const dest_exists = blk: {
        _ = cwd.statFile(cli.dst) catch |err| switch (err) {
            error.FileNotFound => break :blk false,
            else => |e| return e,
        };
        break :blk true;
    };
    if (dest_exists and !cli.force) {
        std.debug.print("error: destination exists; pass --force to overwrite\n", .{});
        std.process.exit(2);
    }

    // 执行原子性复制，默认保留文件权限。成功时不输出任何内容，
    // 以保持管道安静并便于脚本化使用。
    cwd.copyFile(cli.src, cwd, cli.dst, .{ .override_mode = null }) catch |err| {
        std.debug.print("error: copy failed ({s})\n", .{@errorName(err)});
        std.process.exit(1);
    };
}
