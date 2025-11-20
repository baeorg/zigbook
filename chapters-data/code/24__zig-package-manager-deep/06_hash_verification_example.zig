// This example demonstrates how hash verification works conceptually.
// 此 示例 演示 how hash verification works conceptually.
// In practice, Zig handles this automatically during `zig fetch`.
// 在 practice, Zig handles 此 automatically during `zig fetch`.

const std = @import("std");

pub fn main() !void {
    // Simulate fetching a package
    // Simulate fetching 一个 package
    const package_contents = "This is the package source code.";

    // Compute the hash
    // Compute hash
    var hasher = std.crypto.hash.sha2.Sha256.init(.{});
    hasher.update(package_contents);
    var digest: [32]u8 = undefined;
    hasher.final(&digest); // Format as hex for display
    std.debug.print("Package hash: {x}\n", .{digest});
    std.debug.print("Expected hash in build.zig.zon: 1220{x}\n", .{digest});
    std.debug.print("\nNote: The '1220' prefix indicates SHA-256 in multihash format.\n", .{});
}
