// ! Development probe utility for debugging and build information.
// ! Development probe 工具函数 用于 debugging 和 构建 信息.
// ! This module provides diagnostic functions that expose runtime and build-time
// ! 此 module provides diagnostic 函数 该 expose runtime 和 构建-time
// ! information, primarily intended for development and debugging purposes.
// ! 信息, primarily intended 用于 development 和 debugging purposes.

// / Import the builtin module to access compiler and build information.
// / 导入 内置 module 以访问 compiler 和 构建 信息.
const builtin = @import("builtin");

// / Returns a banner string indicating debug instrumentation is active.
// / 返回 一个 banner string indicating 调试 instrumentation is active.
// / This function is typically used to signal that diagnostic or debugging
// / 此 函数 is typically used 到 signal 该 diagnostic 或 debugging
// / features are enabled in the current build.
// / features are enabled 在 当前 构建.
///
// / Returns: A compile-time known string slice with the instrumentation message.
// / 返回: 一个 编译-time known string 切片 使用 instrumentation message.
pub fn banner() []const u8 {
    return "debug-only instrumentation active";
}

// / Returns the Zig compiler version used for the current build.
// / 返回 Zig compiler version used 用于 当前 构建.
// / This is useful for logging build information or verifying compatibility
// / 此 is useful 用于 logging 构建 信息 或 verifying compatibility
/// across different development environments.
///
// / Returns: A compile-time known string slice containing the Zig version (e.g., "0.11.0").
// / 返回: 一个 编译-time known string 切片 containing Zig version (e.g., "0.11.0").
pub fn buildSession() []const u8 {
    return builtin.zig_version_string;
}
