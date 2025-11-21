const std = @import("std");

/// 为演示原生和WASI交叉编译的log-analyzer项目构建脚本。
/// 生成两个可执行文件：一个用于原生执行，一个用于WASI运行时。
pub fn build(b: *std.Build) void {
    // 来自命令行标志的标准目标和优化选项
    // 这些允许用户在构建时指定--target和--optimize
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // 原生可执行文件：为宿主系统上的快速运行时性能进行优化
    // 此目标遵循用户指定的目标和优化设置
    const exe_native = b.addExecutable(.{
        .name = "log-analyzer-native",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    // 注册原生可执行文件以安装到zig-out/bin
    b.installArtifact(exe_native);

    // WASI可执行文件：交叉编译为WebAssembly并支持WASI
    // 使用ReleaseSmall以最小化二进制大小，便于分发
    const wasi_target = b.resolveTargetQuery(.{
        .cpu_arch = .wasm32,
        .os_tag = .wasi,
    });
    const exe_wasi = b.addExecutable(.{
        .name = "log-analyzer-wasi",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = wasi_target,
            .optimize = .ReleaseSmall, // 优先考虑小二进制大小而不是速度
        }),
    });
    // 注册WASI可执行文件以安装到zig-out/bin
    b.installArtifact(exe_wasi);

    // 为原生目标创建运行步骤，直接执行编译的二进制文件
    const run_native = b.addRunArtifact(exe_native);
    // 确保在尝试运行之前构建并安装二进制文件
    run_native.step.dependOn(b.getInstallStep());
    // 转发在--之后传递的任何命令行参数到可执行文件
    if (b.args) |args| {
        run_native.addArgs(args);
    }
    // 注册运行步骤，以便用户可以使用`zig build run-native`调用它
    const run_native_step = b.step("run-native", "Run the native log analyzer");
    run_native_step.dependOn(&run_native.step);

    // 为WASI目标创建运行步骤，带有自动运行时检测
    // 首先，尝试检测可用的WASI运行时（wasmtime或wasmer）
    const run_wasi = b.addSystemCommand(&.{"echo"});
    const wasi_runtime = detectWasiRuntime(b) orelse {
        // 如果找不到运行时，提供有用的错误消息
        run_wasi.addArg("ERROR: No WASI runtime (wasmtime or wasmer) found in PATH");
        const run_wasi_step = b.step("run-wasi", "Run the WASI log analyzer (requires wasmtime or wasmer)");
        run_wasi_step.dependOn(&run_wasi.step);
        return;
    };

    // 构造使用检测到的运行时运行WASI二进制文件的命令
    const run_wasi_cmd = b.addSystemCommand(&.{wasi_runtime});
    // wasmtime和wasmer都需要'run'子命令
    if (std.mem.eql(u8, wasi_runtime, "wasmtime") or std.mem.eql(u8, wasi_runtime, "wasmer")) {
        run_wasi_cmd.addArg("run");
        // 授予对当前目录的访问权限以进行文件I/O操作
        run_wasi_cmd.addArg("--dir=.");
    }
    // 添加WASI二进制文件作为要执行的目标
    run_wasi_cmd.addArtifactArg(exe_wasi);
    // 转发用户在--分隔符之后的参数到WASI程序
    if (b.args) |args| {
        run_wasi_cmd.addArg("--");
        run_wasi_cmd.addArgs(args);
    }
    // 确保在尝试运行之前构建WASI二进制文件
    run_wasi_cmd.step.dependOn(b.getInstallStep());

    // 注册WASI运行步骤，以便用户可以使用`zig build run-wasi`调用它
    const run_wasi_step = b.step("run-wasi", "Run the WASI log analyzer (requires wasmtime or wasmer)");
    run_wasi_step.dependOn(&run_wasi_cmd.step);
}

/// 检测系统PATH中的可用WASI运行时。
/// 首先检查wasmtime，然后检查wasmer作为后备。
/// 返回检测到的运行时的名称，如果都未找到则返回null。
fn detectWasiRuntime(b: *std.Build) ?[]const u8 {
    // 尝试使用'which'命令定位wasmtime
    var exit_code: u8 = undefined;
    _ = b.runAllowFail(&.{ "which", "wasmtime" }, &exit_code, .Ignore) catch {
        // 如果未找到wasmtime，尝试wasmer作为后备
        _ = b.runAllowFail(&.{ "which", "wasmer" }, &exit_code, .Ignore) catch {
            // 在PATH中未找到运行时
            return null;
        };
        return "wasmer";
    };
    // 成功定位了wasmtime
    return "wasmtime";
}
