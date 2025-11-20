const std = @import("std");

// / Represents a target/optimization combination in the build matrix
// / Represents 一个 target/optimization combination 在 构建 matrix
// / Each combo defines a unique build configuration with a descriptive name
// / 每个 combo defines 一个 unique 构建 configuration 使用 一个 descriptive name
const Combo = struct {
    // / Human-readable identifier for this build configuration
    // / Human-readable identifier 用于 此 构建 configuration
    name: []const u8,
    // / Target query specifying the CPU architecture, OS, and ABI
    // / Target query specifying CPU architecture, OS, 和 ABI
    query: std.Target.Query,
    // / Optimization level (Debug, ReleaseSafe, ReleaseFast, or ReleaseSmall)
    // / Optimization level (调试, ReleaseSafe, ReleaseFast, 或 ReleaseSmall)
    optimize: std.builtin.OptimizeMode,
};

pub fn build(b: *std.Build) void {
    // Define a matrix of target/optimization combinations to build
    // 定义一个 matrix 的 target/optimization combinations 到 构建
    // This demonstrates cross-compilation capabilities and optimization strategies
    // 此 演示 cross-compilation capabilities 和 optimization strategies
    const combos = [_]Combo{
        // Native build with debug symbols for development
        // Native 构建 使用 调试 symbols 用于 development
        .{ .name = "native-debug", .query = .{}, .optimize = .Debug },
        // Linux x86_64 build optimized for maximum performance
        // Linux x86_64 构建 optimized 用于 maximum performance
        .{ .name = "linux-fast", .query = .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .gnu }, .optimize = .ReleaseFast },
        // WebAssembly build optimized for minimal binary size
        // WebAssembly 构建 optimized 用于 最小化 binary size
        .{ .name = "wasi-small", .query = .{ .cpu_arch = .wasm32, .os_tag = .wasi }, .optimize = .ReleaseSmall },
    };

    // Create a top-level step that builds all target/optimize combinations
    // 创建一个 top-level step 该 builds 所有 target/optimize combinations
    // Users can invoke this with `zig build matrix`
    // Users can invoke 此 使用 `zig 构建 matrix`
    const matrix_step = b.step("matrix", "Build every target/optimize pair");

    // Track the run step for the first (host) executable to create a sanity check
    // Track run step 用于 首先 (host) executable 到 创建一个 sanity 检查
    var host_run_step: ?*std.Build.Step = null;

    // Iterate through each combo to create and configure build artifacts
    // 遍历 每个 combo 到 创建 和 configure 构建 artifacts
    for (combos, 0..) |combo, index| {
        // Resolve the target query into a concrete target specification
        // Resolve target query into 一个 concrete target specification
        // This validates the query and fills in any unspecified fields with defaults
        // 此 validates query 和 fills 在 any unspecified fields 使用 defaults
        const resolved = b.resolveTargetQuery(combo.query);
        
        // Create a module with the resolved target and optimization settings
        // 创建一个 module 使用 resolved target 和 optimization settings
        // Using createModule allows precise control over compilation parameters
        // 使用 createModule allows precise control over compilation parameters
        const module = b.createModule(.{
            .root_source_file = b.path("matrix/app.zig"),
            .target = resolved,
            .optimize = combo.optimize,
        });

        // Create an executable artifact with a unique name for this combo
        // 创建 一个 executable artifact 使用 一个 unique name 用于 此 combo
        // The name includes the combo identifier to distinguish build outputs
        // name includes combo identifier 到 distinguish 构建 outputs
        const exe = b.addExecutable(.{
            .name = b.fmt("matrix-{s}", .{combo.name}),
            .root_module = module,
        });

        // Install the executable to zig-out/bin for distribution
        // Install executable 到 zig-out/bin 用于 distribution
        b.installArtifact(exe);
        
        // Add this executable's build step as a dependency of the matrix step
        // Add 此 executable's 构建 step 作为 一个 dependency 的 matrix step
        // This ensures all executables are built when running `zig build matrix`
        // 此 确保 所有 executables are built 当 running `zig 构建 matrix`
        matrix_step.dependOn(&exe.step);

        // For the first combo (assumed to be the native/host target),
        // 用于 首先 combo (assumed 到 be native/host target),
        // create a run step for quick testing and validation
        // 创建一个 run step 用于 quick testing 和 validation
        if (index == 0) {
            // Create a command to run the host executable
            // 创建一个 command 到 run host executable
            const run_cmd = b.addRunArtifact(exe);
            
            // Forward any command-line arguments to the executable
            // Forward any command-line arguments 到 executable
            if (b.args) |args| {
                run_cmd.addArgs(args);
            }
            
            // Create a dedicated step for running the host variant
            // 创建一个 dedicated step 用于 running host variant
            const run_step = b.step("run-host", "Run host variant for sanity checks");
            run_step.dependOn(&run_cmd.step);
            
            // Store the run step for later use in the matrix step
            // Store run step 用于 later use 在 matrix step
            host_run_step = run_step;
        }
    }

    // If a host run step was created, add it as a dependency to the matrix step
    // 如果 一个 host run step was created, add it 作为 一个 dependency 到 matrix step
    // This ensures that building the matrix also runs a sanity check on the host executable
    // 此 确保 该 building matrix also runs 一个 sanity 检查 在 host executable
    if (host_run_step) |run_step| {
        matrix_step.dependOn(run_step);
    }
}
