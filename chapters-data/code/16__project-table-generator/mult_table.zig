const std = @import("std");

// / Returns a reference to a buffered stdout writer.
// / 返回 一个 reference 到 一个 缓冲 stdout writer.
// / The buffer and writer are stored in a private struct to persist across calls.
// / 缓冲区 和 writer are stored 在 一个 private struct 到 persist across calls.
fn stdout() *std.Io.Writer {
    const g = struct {
        // Static buffer for stdout writes—survives function returns
        // Static 缓冲区 用于 stdout writes—survives 函数 返回
        var buf: [8192]u8 = undefined;
        // Writer wraps stdout with the buffer; created once
        // Writer wraps stdout 使用 缓冲区; created once
        var w = std.fs.File.stdout().writer(&buf);
    };
    // Return pointer to the writer's generic interface
    // 返回 pointer 到 writer's 通用 接口
    return &g.w.interface;
}

// / Builds an N×N multiplication table at compile time.
// / Builds 一个 N×N multiplication table 在 编译时.
// / Each cell [i][j] holds (i+1) * (j+1) (1-indexed).
// / 每个 cell [i][j] holds (i+1) * (j+1) (1-indexed).
fn buildMulTable(comptime N: usize) [N][N]u16 {
    // Declare the result table; will be computed entirely at compile time
    // Declare result table; will be computed entirely 在 编译时
    var t: [N][N]u16 = undefined;
    
    // Outer loop: row index (compile-time variable required for inline while)
    // Outer loop: row 索引 (编译-time variable 必需 用于 inline 当)
    comptime var i: usize = 0;
    inline while (i < N) : (i += 1) {
        // Inner loop: column index
        // Inner loop: column 索引
        comptime var j: usize = 0;
        inline while (j < N) : (j += 1) {
            // Store (row+1) * (col+1) in the table
            // Store (row+1) * (col+1) 在 table
            t[i][j] = @intCast((i + 1) * (j + 1));
        }
    }
    // Return the fully populated table as a compile-time constant
    // 返回 fully populated table 作为 一个 编译-time constant
    return t;
}

pub fn main() !void {
    // Acquire the buffered stdout writer
    // Acquire 缓冲 stdout writer
    const out = stdout();
    
    // Table dimension (classic 12×12 times table)
    const N = 12;
    
    // Generate the multiplication table at compile time
    // Generate multiplication table 在 编译时
    const T = buildMulTable(N);

    // Print header line
    // 打印 header line
    try out.print("{s}x{s} multiplication table (partial):\n", .{ "12", "12" });
    
    // Print only first 6 rows to keep output concise (runtime loop)
    // 打印 only 首先 6 rows 到 keep 输出 concise (runtime loop)
    var i: usize = 0;
    while (i < 6) : (i += 1) {
        // Print all 12 columns for this row
        // 打印 所有 12 columns 用于 此 row
        var j: usize = 0;
        while (j < N) : (j += 1) {
            // Format each cell right-aligned in a 4-character field
            // Format 每个 cell right-aligned 在 一个 4-character field
            try out.print("{d: >4}", .{T[i][j]});
        }
        // End the row with a newline
        // End row 使用 一个 newline
        try out.print("\n", .{});
    }

    // Flush the buffered writer to ensure all output appears
    // 刷新 缓冲写入器 到 确保 所有 输出 appears
    try out.flush();
}
