// 文件路径: chapters-data/code/01__boot-basics/values_and_literals.zig
const std = @import("std");

pub fn main() !void {
    // 声明带显式类型标注的可变变量
    // u32为无符号32位整数，初始化为1
    var counter: u32 = 1;

    // 声明带推断类型的不可变常量（comptime_int）
    // 编译器从字面值2推断出类型
    const increment = 2;

    // 声明带显式浮点类型的常量
    // f64为64位浮点数
    const ratio: f64 = 0.5;

    // 布尔常量，带推断类型
    // 演示Zig对简单字面值的类型推断
    const flag = true;

    // 表示换行的字符字面值
    // 单字节字符在Zig中是u8值
    const newline: u8 = '\n';

    // 单元类型值，类似于其他语言中的()
    // 显式表示"无值"或"空"
    const unit_value = void{};

    // 通过增加值来修改计数器
    // 只有var声明可以被修改
    counter += increment;

    // 打印显示不同值类型的格式化输出
    // {}是适用于任何类型的通用格式说明符
    std.debug.print("counter={} ratio={} safety={}\n", .{ counter, ratio, flag });

    // 将换行符字节强制转换为u32以显示其ASCII十进制值
    // @as执行显式类型转换
    std.debug.print("newline byte={} (ASCII)\n", .{@as(u32, newline)});

    // 使用编译时反射来打印unit_value的类型名称
    // @TypeOf获取类型，@typeName将其转换为字符串
    std.debug.print("unit literal has type {s}\n", .{@typeName(@TypeOf(unit_value))});
}
