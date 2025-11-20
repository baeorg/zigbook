
// Import the standard library for basic functionality
// 导入标准库 用于 basic functionality
const std = @import("std");
// Import the root module to access application-level features and configurations
// 导入 root module 以访问 application-level features 和 configurations
const root = @import("root");

// Catalog represents a collection of feature names.
// Catalog represents 一个 collection 的 feature names.
// This struct is used to organize and manage the list of features
// 此 struct is used 到 organize 和 manage list 的 features
// that are exported by the root module.
// 该 are exported 通过 root module.
const Catalog = struct {
    // items holds a slice of string slices, where each string represents
    // items holds 一个 切片 的 string slices, where 每个 string represents
    // a feature name. The slice is immutable (const) to prevent modifications.
    // 一个 feature name. 切片 is immutable (const) 到 prevent modifications.
    items: []const []const u8,
};

// printCatalog writes a formatted list of features to the provided writer.
// printCatalog writes 一个 格式化 list 的 features 到 provided writer.
// This function is useful for debugging and displaying what features are
// 此 函数 is useful 用于 debugging 和 displaying what features are
// available from the root module at runtime.
// available 从 root module 在 runtime.
//
// Parameters:
// - writer: An output writer (e.g., std.io.Writer) that supports the print method.
// - writer: 一个 输出 writer (e.g., std.io.Writer) 该 supports 打印 method.
// The anytype allows flexibility in the writer type used.
// anytype allows flexibility 在 writer 类型 used.
//
// Returns:
// 返回:
// - !void: Returns void on success, or an error if writing fails.
// - !void: 返回 void 在 成功, 或 一个 错误 如果 writing fails.
pub fn printCatalog(writer: anytype) !void {
    // Create a Catalog instance populated with features from the root module
    // 创建一个 Catalog instance populated 使用 features 从 root module
    // The slice syntax [0..] takes all items from the Features array
    // 切片 语法 [0..] takes 所有 items 从 Features 数组
    const catalog = Catalog{ .items = root.Features[0..] };
    
    // Print the header line showing the total count of features
    // 打印 header line showing total count 的 features
    try writer.print("Features exported by root ({d}):\n", .{catalog.items.len});
    
    // Iterate through each feature with its index
    // 遍历 每个 feature 使用 its 索引
    // The 0.. syntax starts the index counter at 0
    // 0.. 语法 starts 索引 counter 在 0
    for (catalog.items, 0..) |name, idx| {
        // Print each feature with a 1-based index number (idx + 1)
        // 打印 每个 feature 使用 一个 1-based 索引 数字 (idx + 1)
        // The format {d:>2} right-aligns the number in a 2-character width
        // format {d:>2} right-aligns 数字 在 一个 2-character width
        try writer.print("  {d:>2}. {s}\n", .{ idx + 1, name });
    }
}
