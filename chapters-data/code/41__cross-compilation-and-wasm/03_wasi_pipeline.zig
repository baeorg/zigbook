// 导入标准库以获取调试打印功能
const std = @import("std");
// 导入内置模块以访问编译时目标信息
const builtin = @import("builtin");

//  将阶段名称打印到 stderr 以跟踪执行流程。
//  此辅助函数演示了跨平台上下文中的调试输出。
fn stage(name: []const u8) void {
    std.debug.print("stage: {s}\n", .{name});
}

//  演示基于目标操作系统的条件编译。
//  此示例展示了 Zig 代码如何根据
//  它是为 WASI（WebAssembly 系统接口）还是原生平台编译，在编译时进行分支。
//  执行流程根据目标变化，说明了交叉编译功能。
pub fn main() void {
    // 模拟初始参数解析阶段
    stage("parse-args");
    // 模拟有效负载渲染阶段
    stage("render-payload");

    // 编译时分支：WASI 与原生目标的不同入口点
    // 这演示了 Zig 如何处理平台特定的代码路径
    if (builtin.target.os.tag == .wasi) {
        stage("wasi-entry");
    } else {
        stage("native-entry");
    }

    // 打印编译目标的实际 OS 标签名
    // @tagName 将枚举值转换为其字符串表示
    stage(@tagName(builtin.target.os.tag));
}
