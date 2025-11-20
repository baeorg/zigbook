// ! TextKit - A text processing library
// ! TextKit - 一个 text processing 库
//!
// ! This library provides utilities for text manipulation and analysis,
// ! 此 库 provides utilities 用于 text manipulation 和 analysis,
// ! including string utilities and text statistics.
// ! including string utilities 和 text statistics.

pub const StringUtils = @import("string_utils.zig").StringUtils;
pub const TextStats = @import("text_stats.zig").TextStats;

const std = @import("std");

// / Library version information
// / 库 version 信息
pub const version = std.SemanticVersion{
    .major = 1,
    .minor = 0,
    .patch = 0,
};

test {
    // Ensure all module tests are run
    // 确保 所有 module tests are run
    std.testing.refAllDecls(@This());
}
