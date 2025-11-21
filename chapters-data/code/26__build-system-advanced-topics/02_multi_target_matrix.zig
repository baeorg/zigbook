const std = @import("std");

/// 表示构建矩阵中目标/优化组合的结构
/// 每个组合定义具有描述性名称的唯一构建配置
const Combo = struct {
    // 构建配置的人类可读标识符
    name: []const u8,
    // 指定CPU架构、操作系统和ABI的目标查询
    query: std.Target.Query,
    // 优化级别（Debug、ReleaseSafe、ReleaseFast或ReleaseSmall）
    optimize: std.builtin.OptimizeMode,
};

pub fn build(b: *std.Build) void {
    // 定义要构建的目标/优化组合矩阵
    // 这演示了交叉编译能力和优化策略
    const combos = [_]Combo{
        // 用于开发的带调试符号的原生构建
        .{ .name = "native-debug", .query = .{}, .optimize = .Debug },
        // 针对最大性能优化的Linux x86_64构建
        .{ .name = "linux-fast", .query = .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .gnu }, .optimize = .ReleaseFast },
        // 针对最小二进制大小优化的WebAssembly构建
        .{ .name = "wasi-small", .query = .{ .cpu_arch = .wasm32, .os_tag = .wasi }, .optimize = .ReleaseSmall },
    };

    // 创建构建所有目标/优化组合的顶级步骤
    // 用户可以使用`zig build matrix`调用
    const matrix_step = b.step("matrix", "Build every target/optimize pair");

    // 跟踪第一个（主机）可执行文件的运行步骤以创建健全性检查
    var host_run_step: ?*std.Build.Step = null;

    // 迭代每个组合以创建和配置构建工件
    for (combos, 0..) |combo, index| {
        // 将目标查询解析为具体的目标规范
        // 这验证查询并用默认值填充任何未指定的字段
        const resolved = b.resolveTargetQuery(combo.query);

        // 使用解析的目标和优化设置创建模块
        // 使用createModule允许对编译参数进行精确控制
        const module = b.createModule(.{
            .root_source_file = b.path("matrix/app.zig"),
            .target = resolved,
            .optimize = combo.optimize,
        });

        // 为此组合创建具有唯一名称的可执行文件工件
        // 名称包括组合标识符以区分构建输出
        const exe = b.addExecutable(.{
            .name = b.fmt("matrix-{s}", .{combo.name}),
            .root_module = module,
        });

        // 将可执行文件安装到zig-out/bin以便分发
        b.installArtifact(exe);

        // 将此可执行文件的构建步骤添加为矩阵步骤的依赖项
        // 这确保在运行`zig build matrix`时构建所有可执行文件
        matrix_step.dependOn(&exe.step);

        // 对于第一个组合（假定为主机/宿主目标），
        // 为快速测试和验证创建运行步骤
        if (index == 0) {
            // 创建运行主机可执行文件的命令
            const run_cmd = b.addRunArtifact(exe);

            // 将任何命令行参数转发到可执行文件
            if (b.args) |args| {
                run_cmd.addArgs(args);
            }

            // 创建用于运行主机变体的专用步骤
            const run_step = b.step("run-host", "Run host variant for sanity checks");
            run_step.dependOn(&run_cmd.step);

            // 存储运行步骤以供矩阵步骤后续使用
            host_run_step = run_step;
        }
    }

    // 如果创建了主机运行步骤，将其添加为矩阵步骤的依赖项
    // 这确保构建矩阵也在主机可执行文件上运行健全性检查
    if (host_run_step) |run_step| {
        matrix_step.dependOn(run_step);
    }
}
