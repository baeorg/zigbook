const std = @import("std");

/// 表示具有数值读数的传感器设备的简单结构
const Sensor = struct {
    reading: i32,
};

/// 将传感器的读数值打印到调试输出
/// 接受指向传感器的单个指针并显示其当前读数
fn report(label: []const u8, ptr: *Sensor) void {
    std.debug.print("{s} -> reading {d}\n", .{ label, ptr.reading });
}

/// 演示Zig中的指针基础、可选指针和多项目指针
/// 本示例涵盖：
/// - 单项目指针（*T）和指针解引用
/// - 指针别名和通过别名进行修改
/// - 用于表示可空引用的可选指针（?*T）
/// - 使用if语句解包可选指针
/// - 用于未检查多元素访问的多项目指针（[*]T）
/// - 通过.ptr属性将切片转换为多项目指针
pub fn main() !void {
    // 在栈上创建传感器实例
    var sensor = Sensor{ .reading = 41 };

    // 创建传感器的单项目指针别名
    // &操作符获取传感器的地址
    var alias: *Sensor = &sensor;

    // 通过指针别名修改传感器
    // Zig自动解引用指针字段
    alias.reading += 1;

    report("alias", alias);

    // 声明初始化为null的可选指针
    // ?*T表示可能持有或不持有有效地址的指针
    var maybe_alias: ?*Sensor = null;

    // 尝试解包可选指针
    // 此分支不会执行，因为maybe_alias为null
    if (maybe_alias) |pointer| {
        std.debug.print("unexpected pointer: {d}\n", .{pointer.reading});
    } else {
        std.debug.print("optional pointer empty\n", .{});
    }

    // 将有效地址赋值给可选指针
    maybe_alias = &sensor;

    // 解包并使用可选指针
    // |pointer|捕获语法提取非空值
    if (maybe_alias) |pointer| {
        pointer.reading += 10;
        std.debug.print("optional pointer mutated to {d}\n", .{sensor.reading});
    }

    // 创建数组及其切片视图
    var samples = [_]i32{ 5, 7, 9, 11 };
    const view: []i32 = samples[0..];

    // 从切片中提取多项目指针
    // 多项目指针（[*]T）允许不带长度跟踪的未检查索引
    const many: [*]i32 = view.ptr;

    // 通过多项目指针修改底层数组
    // 此时不执行边界检查
    many[2] = 42;

    std.debug.print("slice view len={}\n", .{view.len});
    // 验证通过多项目指针的修改影响了原始数组
    std.debug.print("samples[2] via many pointer = {d}\n", .{samples[2]});
}
