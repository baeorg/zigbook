const std = @import("std");

//  传递给 HTTP 服务器线程的参数，使其能够响应单个请求。
const HttpTask = struct {
    server: *std.net.Server,
    ready: *std.Thread.ResetEvent,
};

//  最小化的 HTTP 处理程序：接受一个客户端，用 JSON 文档回复，然后退出。
fn serveJson(task: HttpTask) void {
    // 通知主线程服务器线程已进入接受循环。
    // 这种同步机制防止客户端在服务器准备好之前尝试连接。
    task.ready.set();

    // 阻塞直到客户端连接；优雅地处理连接错误
    const connection = task.server.accept() catch |err| {
        std.debug.print("accept failed: {s}\n", .{@errorName(err)});
        return;
    };
    // 确保此函数退出时连接已关闭
    defer connection.stream.close();

    // 分配用于接收 HTTP 请求和发送 HTTP 响应的缓冲区
    var recv_buffer: [4096]u8 = undefined;
    var send_buffer: [4096]u8 = undefined;
    // 为 TCP 连接创建缓冲读取器和写入器
    var conn_reader = connection.stream.reader(&recv_buffer);
    var conn_writer = connection.stream.writer(&send_buffer);
    // 使用缓冲连接接口初始化 HTTP 服务器状态机
    var server = std.http.Server.init(conn_reader.interface(), &conn_writer.interface);

    // 解析 HTTP 请求头（方法、路径、版本等）
    var request = server.receiveHead() catch |err| {
        std.debug.print("receive head failed: {s}\n", .{@errorName(err)});
        return;
    };

    // 定义 JSON 响应有效负载的形状
    const Body = struct {
        service: []const u8,
        message: []const u8,
        method: []const u8,
        path: []const u8,
        sequence: u32,
    };

    // 构建一个回显请求详细信息给客户端的响应
    const payload = Body{
        .service = "loopback-api",
        .message = "hello from Zig HTTP server",
        .method = @tagName(request.head.method), // 将 HTTP 方法枚举转换为字符串
        .path = request.head.target, // 回显请求的路径
        .sequence = 1,
    };

    // 为 JSON 编码的响应体分配缓冲区
    var json_buffer: [256]u8 = undefined;
    // 创建一个固定大小的写入器，写入我们的缓冲区
    var body_writer = std.Io.Writer.fixed(json_buffer[0..]);
    // 将有效负载结构序列化为 JSON 格式
    std.json.Stringify.value(payload, .{}, &body_writer) catch |err| {
        std.debug.print("json encode failed: {s}\n", .{@errorName(err)});
        return;
    };
    // 获取包含实际写入的 JSON 字节的切片
    const body = std.Io.Writer.buffered(&body_writer);

    // 发送 HTTP 200 响应，包含 JSON 正文和适当的 Content-Type 头
    request.respond(body, .{
        .extra_headers = &.{
            .{ .name = "content-type", .value = "application/json" },
        },
    }) catch |err| {
        std.debug.print("respond failed: {s}\n", .{@errorName(err)});
        return;
    };
}

pub fn main() !void {
    // 初始化分配器以满足动态内存需求（HTTP 客户端需要分配）
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // 在 127.0.0.1 上创建一个回环服务器，使用操作系统分配的端口（端口 0）
    const address = try std.net.Address.parseIp("127.0.0.1", 0);
    var server = try address.listen(.{ .reuse_address = true });
    defer server.deinit();

    // 创建一个同步原语以协调服务器就绪状态
    var ready = std.Thread.ResetEvent{};
    // 启动服务器线程，该线程将接受并处理一个 HTTP 请求
    const server_thread = try std.Thread.spawn(.{}, serveJson, .{HttpTask{
        .server = &server,
        .ready = &ready,
    }});
    // 确保服务器线程在 main() 退出前完成
    defer server_thread.join();

    // 阻塞直到服务器线程发出已到达 accept() 的信号
    // 这可以防止客户端过早尝试连接的竞态条件
    ready.wait();

    // 检索客户端连接的动态分配端口号
    const port = server.listen_address.in.getPort();

    // 使用我们的分配器初始化 HTTP 客户端
    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();

    // 构造 HTTP 请求的完整 URL
    var url_buffer: [64]u8 = undefined;
    const url = try std.fmt.bufPrint(&url_buffer, "http://127.0.0.1:{d}/stats", .{port});

    // 分配缓冲区以接收 HTTP 响应体
    var response_buffer: [512]u8 = undefined;
    // 创建一个固定大小的写入器，将捕获响应
    var response_writer = std.Io.Writer.fixed(response_buffer[0..]);

    // 执行带有自定义 User-Agent 头部的 HTTP GET 请求
    const fetch_result = try client.fetch(.{
        .location = .{ .url = url },
        .response_writer = &response_writer, // 写入响应体的位置
        .headers = .{
            .user_agent = .{ .override = "zigbook-demo/0.15.2" },
        },
    });

    // 获取包含实际响应体字节的切片
    const body = std.Io.Writer.buffered(&response_writer);

    // 定义 JSON 响应的预期结构
    const ResponseShape = struct {
        service: []const u8,
        message: []const u8,
        method: []const u8,
        path: []const u8,
        sequence: u32,
    };

    // 将 JSON 响应解析为类型化的结构体
    var parsed = try std.json.parseFromSlice(ResponseShape, allocator, body, .{});
    // 释放 JSON 解析期间分配的内存
    defer parsed.deinit();

    // 设置一个缓冲写入器以高效地将结果输出到标准输出
    var stdout_storage: [256]u8 = undefined;
    var stdout_state = std.fs.File.stdout().writer(&stdout_storage);
    const out = &stdout_state.interface;
    // 显示 HTTP 响应状态码
    try out.print("status: {d}\n", .{@intFromEnum(fetch_result.status)});
    // 显示解析后的 JSON 字段
    try out.print("service: {s}\n", .{parsed.value.service});
    try out.print("method: {s}\n", .{parsed.value.method});
    try out.print("path: {s}\n", .{parsed.value.path});
    try out.print("message: {s}\n", .{parsed.value.message});
    // 确保在程序退出前所有输出可见
    try out.flush();
}
