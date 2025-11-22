// ! 使用 Zig 基于 defer 的清理机制重新实现 C 风格的缓冲区复制。
const std = @import("std");

pub const NormalizeError = error{InvalidCharacter} || std.mem.Allocator.Error;

pub fn duplicateAlphaUpper(allocator: std.mem.Allocator, input: []const u8) NormalizeError![]u8 {
    const buffer = try allocator.alloc(u8, input.len);
    errdefer allocator.free(buffer);

    for (buffer, input) |*dst, src| switch (src) {
        'a'...'z', 'A'...'Z' => dst.* = std.ascii.toUpper(src),
        else => return NormalizeError.InvalidCharacter,
    };

    return buffer;
}

pub fn cStyleDuplicateAlphaUpper(allocator: std.mem.Allocator, input: []const u8) NormalizeError![]u8 {
    const buffer = try allocator.alloc(u8, input.len);
    var ok = false;
    defer if (!ok) allocator.free(buffer);

    for (buffer, input) |*dst, src| switch (src) {
        'a'...'z', 'A'...'Z' => dst.* = std.ascii.toUpper(src),
        else => return NormalizeError.InvalidCharacter,
    };

    ok = true;
    return buffer;
}

test "duplicateAlphaUpper releases buffer on failure" {
    const allocator = std.testing.allocator;
    try std.testing.expectError(NormalizeError.InvalidCharacter, duplicateAlphaUpper(allocator, "zig-0"));
}

test "c style duplicate succeeds with valid input" {
    const allocator = std.testing.allocator;
    const dup = try cStyleDuplicateAlphaUpper(allocator, "zig");
    defer allocator.free(dup);
    try std.testing.expectEqualStrings("ZIG", dup);
}
