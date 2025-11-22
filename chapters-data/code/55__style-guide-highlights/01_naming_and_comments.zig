// ! 演示小型诊断辅助函数的命名和文档约定。
const std = @import("std");

// / 表示诊断期间捕获的带标签的温度读数。
pub const TemperatureReading = struct {
    label: []const u8,
    value_celsius: f32,

    // / 使用规范的大小写和单位将读数写入提供的写入器。
    pub fn format(self: TemperatureReading, writer: anytype) !void {
        try writer.print("{s}: {d:.1}°C", .{ self.label, self.value_celsius });
    }
};

// / 使用给定标签和摄氏温度值创建读数。
pub fn createReading(label: []const u8, value_celsius: f32) TemperatureReading {
    return .{
        .label = label,
        .value_celsius = value_celsius,
    };
}

test "temperature readings print with consistent label casing" {
    const reading = createReading("CPU", 72.25);
    var backing: [64]u8 = undefined;
    var stream = std.io.fixedBufferStream(&backing);

    try reading.format(stream.writer());
    const rendered = stream.getWritten();

    try std.testing.expectEqualStrings("CPU: 72.3°C", rendered);
}
