const std = @import("std");

// Chapter 5 – TempConv CLI: walk from parsing arguments through producing a
// 第5章 - TempConv CLI：从解析参数到生成格式化结果的完整过程
// formatted result, exercising everything we have learned about errors and
// 练习我们学到的所有错误处理和
// deterministic cleanup along the way.
// 确定性清理知识。

const CliError = error{ MissingArgs, BadNumber, BadUnit };

const Unit = enum { c, f, k };

fn printUsage() void {
    std.debug.print("usage: tempconv <value> <from-unit> <to-unit>\n", .{});
    std.debug.print("units: C (celsius), F (fahrenheit), K (kelvin)\n", .{});
}

fn parseUnit(token: []const u8) CliError!Unit {
    // Section 1: we accept a single-letter token and normalise it so the CLI
    // 第1节：我们接受单个字母标记并规范化它，以便CLI对大小写保持宽容。
    if (token.len != 1) return CliError.BadUnit;
    const ascii = std.ascii;
    const lower = ascii.toLower(token[0]);
    return switch (lower) {
        'c' => .c,
        'f' => .f,
        'k' => .k,
        else => CliError.BadUnit,
    };
}

fn toKelvin(value: f64, unit: Unit) f64 {
    return switch (unit) {
        .c => value + 273.15,
        .f => (value + 459.67) * 5.0 / 9.0,
        .k => value,
    };
}

fn fromKelvin(value: f64, unit: Unit) f64 {
    return switch (unit) {
        .c => value - 273.15,
        .f => (value * 9.0 / 5.0) - 459.67,
        .k => value,
    };
}

fn convert(value: f64, from: Unit, to: Unit) f64 {
    // 第2节：通过开尔文进行标准化，使每对单位都能重用
    // 相同的公式，保持CLI易于扩展。
    if (from == to) return value;
    const kelvin = toKelvin(value, from);
    return fromKelvin(kelvin, to);
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len == 1 or (args.len == 2 and std.mem.eql(u8, args[1], "--help"))) {
        printUsage();
        return;
    }

    if (args.len != 4) {
        std.debug.print("error: expected three arguments\n", .{});
        printUsage();
        std.process.exit(1);
    }

    const raw_value = args[1];
    const value = std.fmt.parseFloat(f64, raw_value) catch {
        // 第1节还突出了解析失败如何成为面向用户的
        // 诊断信息，而不是堆栈跟踪。
        std.debug.print("error: '{s}' is not a floating-point value\n", .{raw_value});
        std.process.exit(1);
    };

    const from = parseUnit(args[2]) catch {
        std.debug.print("error: unknown unit '{s}'\n", .{args[2]});
        std.process.exit(1);
    };

    const to = parseUnit(args[3]) catch {
        std.debug.print("error: unknown unit '{s}'\n", .{args[3]});
        std.process.exit(1);
    };

    const result = convert(value, from, to);

    std.debug.print(
        "{d:.2} {s} -> {d:.2} {s}\n",
        .{ value, @tagName(from), result, @tagName(to) },
    );
}
