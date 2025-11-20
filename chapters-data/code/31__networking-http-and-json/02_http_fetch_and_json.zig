const std = @import("std");

// / Arguments passed to the HTTP server thread so it can respond to a single request.
// / Arguments passed 到 HTTP server thread so it can respond 到 一个 single request.
const HttpTask = struct {
    server: *std.net.Server,
    ready: *std.Thread.ResetEvent,
};

// / Minimal HTTP handler: accept one client, reply with a JSON document, and exit.
// / 最小化 HTTP handler: accept 一个 client, reply 使用 一个 JSON document, 和 退出.
fn serveJson(task: HttpTask) void {
    // Signal the main thread that the server thread reached the accept loop.
    // Signal 主 thread 该 server thread reached accept loop.
    // This synchronization prevents the client from attempting connection before the server is ready.
    // 此 synchronization prevents client 从 attempting connection before server is ready.
    task.ready.set();

    // Block until a client connects; handle connection errors gracefully
    // Block until 一个 client connects; 处理 connection 错误 gracefully
    const connection = task.server.accept() catch |err| {
        std.debug.print("accept failed: {s}\n", .{@errorName(err)});
        return;
    };
    // Ensure the connection is closed when this function exits
    // 确保 connection is closed 当 此 函数 exits
    defer connection.stream.close();

    // Allocate buffers for receiving HTTP request and sending HTTP response
    // 分配 buffers 用于 receiving HTTP request 和 sending HTTP response
    var recv_buffer: [4096]u8 = undefined;
    var send_buffer: [4096]u8 = undefined;
    // Create buffered reader and writer for the TCP connection
    // 创建 缓冲 reader 和 writer 用于 TCP connection
    var conn_reader = connection.stream.reader(&recv_buffer);
    var conn_writer = connection.stream.writer(&send_buffer);
    // Initialize HTTP server state machine with the buffered connection interfaces
    // Initialize HTTP server state machine 使用 缓冲 connection interfaces
    var server = std.http.Server.init(conn_reader.interface(), &conn_writer.interface);

    // Parse the HTTP request headers (method, path, version, etc.)
    // Parse HTTP request headers (method, 路径, version, 等.)
    var request = server.receiveHead() catch |err| {
        std.debug.print("receive head failed: {s}\n", .{@errorName(err)});
        return;
    };

    // Define the shape of our JSON response payload
    // 定义 shape 的 our JSON response 载荷
    const Body = struct {
        service: []const u8,
        message: []const u8,
        method: []const u8,
        path: []const u8,
        sequence: u32,
    };

    // Build a response that echoes request details back to the client
    // 构建 一个 response 该 echoes request details back 到 client
    const payload = Body{
        .service = "loopback-api",
        .message = "hello from Zig HTTP server",
        .method = @tagName(request.head.method), // Convert HTTP method enum to string
        .path = request.head.target, // Echo the requested path
        .sequence = 1,
    };

    // Allocate a buffer for the JSON-encoded response body
    // 分配 一个 缓冲区 用于 JSON-encoded response body
    var json_buffer: [256]u8 = undefined;
    // Create a fixed-size writer that writes into our buffer
    // 创建一个 fixed-size writer 该 writes into our 缓冲区
    var body_writer = std.Io.Writer.fixed(json_buffer[0..]);
    // Serialize the payload struct into JSON format
    // Serialize 载荷 struct into JSON format
    std.json.Stringify.value(payload, .{}, &body_writer) catch |err| {
        std.debug.print("json encode failed: {s}\n", .{@errorName(err)});
        return;
    };
    // Get the slice containing the actual JSON bytes written
    // 获取 切片 containing actual JSON bytes written
    const body = std.Io.Writer.buffered(&body_writer);

    // Send HTTP 200 response with the JSON body and appropriate content-type header
    // Send HTTP 200 response 使用 JSON body 和 appropriate content-类型 header
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
    // Initialize allocator for dynamic memory needs (HTTP client requires allocation)
    // Initialize allocator 用于 dynamic 内存 needs (HTTP client requires allocation)
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create a loopback server on 127.0.0.1 with an OS-assigned port (port 0)
    // 创建一个 loopback server 在 127.0.0.1 使用 一个 OS-assigned port (port 0)
    const address = try std.net.Address.parseIp("127.0.0.1", 0);
    var server = try address.listen(.{ .reuse_address = true });
    defer server.deinit();

    // Create a synchronization primitive to coordinate server readiness
    // 创建一个 synchronization primitive 到 coordinate server readiness
    var ready = std.Thread.ResetEvent{};
    // Spawn the server thread that will accept and handle one HTTP request
    // Spawn server thread 该 will accept 和 处理 一个 HTTP request
    const server_thread = try std.Thread.spawn(.{}, serveJson, .{HttpTask{
        .server = &server,
        .ready = &ready,
    }});
    // Ensure the server thread completes before main() exits
    // 确保 server thread completes before 主() exits
    defer server_thread.join();

    // Block until the server thread signals it has reached accept()
    // Block until server thread signals it has reached accept()
    // This prevents a race condition where the client tries to connect too early
    // 此 prevents 一个 race condition where client tries 到 connect too early
    ready.wait();

    // Retrieve the dynamically assigned port number for the client connection
    // Retrieve dynamically assigned port 数字 用于 client connection
    const port = server.listen_address.in.getPort();

    // Initialize HTTP client with our allocator
    // Initialize HTTP client 使用 our allocator
    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();

    // Construct the full URL for the HTTP request
    // Construct 满 URL 用于 HTTP request
    var url_buffer: [64]u8 = undefined;
    const url = try std.fmt.bufPrint(&url_buffer, "http://127.0.0.1:{d}/stats", .{port});

    // Allocate buffer to receive the HTTP response body
    // 分配 缓冲区 到 receive HTTP response body
    var response_buffer: [512]u8 = undefined;
    // Create a fixed-size writer that will capture the response
    // 创建一个 fixed-size writer 该 will 捕获 response
    var response_writer = std.Io.Writer.fixed(response_buffer[0..]);

    // Perform the HTTP GET request with custom User-Agent header
    // 执行 HTTP 获取 request 使用 自定义 User-Agent header
    const fetch_result = try client.fetch(.{
        .location = .{ .url = url },
        .response_writer = &response_writer, // Where to write response body
        .headers = .{
            .user_agent = .{ .override = "zigbook-demo/0.15.2" },
        },
    });

    // Get the slice containing the actual response body bytes
    // 获取 切片 containing actual response body bytes
    const body = std.Io.Writer.buffered(&response_writer);

    // Define the expected structure of the JSON response
    // 定义 expected structure 的 JSON response
    const ResponseShape = struct {
        service: []const u8,
        message: []const u8,
        method: []const u8,
        path: []const u8,
        sequence: u32,
    };

    // Parse the JSON response into a typed struct
    // Parse JSON response into 一个 typed struct
    var parsed = try std.json.parseFromSlice(ResponseShape, allocator, body, .{});
    // Free the memory allocated during JSON parsing
    // 释放 内存 allocated during JSON 解析
    defer parsed.deinit();

    // Set up a buffered writer for stdout to efficiently output results
    // Set up 一个 缓冲写入器 用于 stdout 到 efficiently 输出 results
    var stdout_storage: [256]u8 = undefined;
    var stdout_state = std.fs.File.stdout().writer(&stdout_storage);
    const out = &stdout_state.interface;
    // Display the HTTP response status code
    // 显示 HTTP response 状态 代码
    try out.print("status: {d}\n", .{@intFromEnum(fetch_result.status)});
    // Display the parsed JSON fields
    // 显示 parsed JSON fields
    try out.print("service: {s}\n", .{parsed.value.service});
    try out.print("method: {s}\n", .{parsed.value.method});
    try out.print("path: {s}\n", .{parsed.value.path});
    try out.print("message: {s}\n", .{parsed.value.message});
    // Ensure all output is visible before program exits
    // 确保 所有 输出 is visible before program exits
    try out.flush();
}
