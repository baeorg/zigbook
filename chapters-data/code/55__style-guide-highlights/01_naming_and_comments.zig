// ! Demonstrates naming and documentation conventions for a small diagnostic helper.
// ! 演示 naming 和 文档 conventions 用于 一个 small diagnostic helper.
const std = @import("std");

// / Represents a labelled temperature reading captured during diagnostics.
// / Represents 一个 labelled 温度 reading captured during diagnostics.
pub const TemperatureReading = struct {
    label: []const u8,
    value_celsius: f32,

    // / Writes the reading to the provided writer using canonical casing and units.
    // / Writes reading 到 provided writer 使用 canonical casing 和 units.
    pub fn format(self: TemperatureReading, writer: anytype) !void {
        try writer.print("{s}: {d:.1}°C", .{ self.label, self.value_celsius });
    }
};

// / Creates a reading with the given label and temperature value in Celsius.
// / Creates 一个 reading 使用 given 标签 和 温度 值 在 Celsius.
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
