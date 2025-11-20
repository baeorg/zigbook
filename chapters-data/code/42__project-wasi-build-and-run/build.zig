const std = @import("std");

// / Build script for log-analyzer project demonstrating native and WASI cross-compilation.
// / 构建 script 用于 log-analyzer project demonstrating native 和 WASI cross-compilation.
// / Produces two executables: one for native execution and one for WASI runtimes.
// / Produces 两个 executables: 一个 用于 native execution 和 一个 用于 WASI runtimes.
pub fn build(b: *std.Build) void {
    // Standard target and optimization options from command-line flags
    // 标准 target 和 optimization options 从 command-line flags
    // These allow users to specify --target and --optimize when building
    // 这些 allow users 到 specify --target 和 --optimize 当 building
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Native executable: optimized for fast runtime performance on the host system
    // Native executable: optimized 用于 fast runtime performance 在 host system
    // This target respects user-specified target and optimization settings
    // 此 target respects user-specified target 和 optimization settings
    const exe_native = b.addExecutable(.{
        .name = "log-analyzer-native",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    // Register the native executable for installation to zig-out/bin
    // Register native executable 用于 installation 到 zig-out/bin
    b.installArtifact(exe_native);

    // WASI executable: cross-compiled to WebAssembly with WASI support
    // WASI executable: cross-compiled 到 WebAssembly 使用 WASI support
    // Uses ReleaseSmall to minimize binary size for portable distribution
    // 使用 ReleaseSmall 到 minimize binary size 用于 portable distribution
    const wasi_target = b.resolveTargetQuery(.{
        .cpu_arch = .wasm32,
        .os_tag = .wasi,
    });
    const exe_wasi = b.addExecutable(.{
        .name = "log-analyzer-wasi",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = wasi_target,
            .optimize = .ReleaseSmall, // Prioritize small binary size over speed
        }),
    });
    // Register the WASI executable for installation to zig-out/bin
    // Register WASI executable 用于 installation 到 zig-out/bin
    b.installArtifact(exe_wasi);

    // Create run step for native target that executes the compiled binary directly
    // 创建 run step 用于 native target 该 executes compiled binary directly
    const run_native = b.addRunArtifact(exe_native);
    // Ensure the binary is built and installed before attempting to run it
    // 确保 binary is built 和 installed before attempting 到 run it
    run_native.step.dependOn(b.getInstallStep());
    // Forward any command-line arguments passed after -- to the executable
    // Forward any command-line arguments passed after -- 到 executable
    if (b.args) |args| {
        run_native.addArgs(args);
    }
    // Register the run step so users can invoke it with `zig build run-native`
    // Register run step so users can invoke it 使用 `zig 构建 run-native`
    const run_native_step = b.step("run-native", "Run the native log analyzer");
    run_native_step.dependOn(&run_native.step);

    // Create run step for WASI target with automatic runtime detection
    // 创建 run step 用于 WASI target 使用 automatic runtime detection
    // First, attempt to detect an available WASI runtime (wasmtime or wasmer)
    // 首先, 尝试 detect 一个 available WASI runtime (wasmtime 或 wasmer)
    const run_wasi = b.addSystemCommand(&.{"echo"});
    const wasi_runtime = detectWasiRuntime(b) orelse {
        // If no runtime is found, provide a helpful error message
        // 如果 不 runtime is found, provide 一个 helpful 错误 message
        run_wasi.addArg("ERROR: No WASI runtime (wasmtime or wasmer) found in PATH");
        const run_wasi_step = b.step("run-wasi", "Run the WASI log analyzer (requires wasmtime or wasmer)");
        run_wasi_step.dependOn(&run_wasi.step);
        return;
    };

    // Construct the command to run the WASI binary with the detected runtime
    // Construct command 到 run WASI binary 使用 detected runtime
    const run_wasi_cmd = b.addSystemCommand(&.{wasi_runtime});
    // Both wasmtime and wasmer require the 'run' subcommand
    // Both wasmtime 和 wasmer require 'run' subcommand
    if (std.mem.eql(u8, wasi_runtime, "wasmtime") or std.mem.eql(u8, wasi_runtime, "wasmer")) {
        run_wasi_cmd.addArg("run");
        // Grant access to the current directory for file I/O operations
        // Grant access 到 当前 directory 用于 文件 I/O operations
        run_wasi_cmd.addArg("--dir=.");
    }
    // Add the WASI binary as the target to execute
    // Add WASI binary 作为 target 到 execute
    run_wasi_cmd.addArtifactArg(exe_wasi);
    // Forward user arguments after the -- separator to the WASI program
    // Forward user arguments after -- separator 到 WASI program
    if (b.args) |args| {
        run_wasi_cmd.addArg("--");
        run_wasi_cmd.addArgs(args);
    }
    // Ensure the WASI binary is built before attempting to run it
    // 确保 WASI binary is built before attempting 到 run it
    run_wasi_cmd.step.dependOn(b.getInstallStep());

    // Register the WASI run step so users can invoke it with `zig build run-wasi`
    // Register WASI run step so users can invoke it 使用 `zig 构建 run-wasi`
    const run_wasi_step = b.step("run-wasi", "Run the WASI log analyzer (requires wasmtime or wasmer)");
    run_wasi_step.dependOn(&run_wasi_cmd.step);
}

// / Detect available WASI runtime in the system PATH.
// / Detect available WASI runtime 在 system 路径.
// / Checks for wasmtime first, then wasmer as a fallback.
// / Checks 用于 wasmtime 首先, 那么 wasmer 作为 一个 fallback.
// / Returns the name of the detected runtime, or null if neither is found.
// / 返回 name 的 detected runtime, 或 空 如果 neither is found.
fn detectWasiRuntime(b: *std.Build) ?[]const u8 {
    // Attempt to locate wasmtime using the 'which' command
    // 尝试 locate wasmtime 使用 'which' command
    var exit_code: u8 = undefined;
    _ = b.runAllowFail(&.{ "which", "wasmtime" }, &exit_code, .Ignore) catch {
        // If wasmtime is not found, try wasmer as a fallback
        // 如果 wasmtime is 不 found, try wasmer 作为 一个 fallback
        _ = b.runAllowFail(&.{ "which", "wasmer" }, &exit_code, .Ignore) catch {
            // Neither runtime was found in PATH
            // Neither runtime was found 在 路径
            return null;
        };
        return "wasmer";
    };
    // wasmtime was successfully located
    return "wasmtime";
}
