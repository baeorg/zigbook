const std = @import("std");

//  传递给服务器线程的参数，使其能够准确接受一个客户端并进行回复。
const ServerTask = struct {
    server: *std.net.Server,
    ready: *std.Thread.ResetEvent,
};

//  从 `std.Io.Reader` 中读取单行，并移除末尾的换行符。
//  如果在读取任何字节之前流结束，则返回 `null`。
fn readLine(reader: *std.Io.Reader, buffer: []u8) !?[]const u8 {
    var len: usize = 0;
    while (true) {
        // 尝试从流中读取单个字节
        const byte = reader.takeByte() catch |err| switch (err) {
            error.EndOfStream => {
                // 流结束：如果没有读取到数据则返回 null，否则返回已读取到的内容
                if (len == 0) return null;
                return buffer[0..len];
            },
            else => return err,
        };

        // 遇到换行符时完成读取行
        if (byte == '\n') return buffer[0..len];
        // 跳过回车符以处理 Unix (\n) 和 Windows (\r\n) 两种换行符
        if (byte == '\r') continue;

        // 防止缓冲区溢出
        if (len == buffer.len) return error.StreamTooLong;
        buffer[len] = byte;
        len += 1;
    }
}

// / 阻塞等待单个客户端，回显客户端发送的内容，然后退出。
fn serveOne(task: ServerTask) void {
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

    // 设置一个缓冲读取器以接收来自客户端的数据
    var inbound_storage: [128]u8 = undefined;
    var net_reader = connection.stream.reader(&inbound_storage);
    const conn_reader = net_reader.interface();

    // 使用自定义的行读取逻辑从客户端读取一行
    var line_storage: [128]u8 = undefined;
    const maybe_line = readLine(conn_reader, &line_storage) catch |err| {
        std.debug.print("receive failed: {s}\n", .{@errorName(err)});
        return;
    };

    // 处理连接在未发送数据的情况下关闭的情况
    const line = maybe_line orelse {
        std.debug.print("connection closed before any data arrived\n", .{});
        return;
    };

    // 清理接收行中任何尾随的空白字符
    const trimmed = std.mem.trimRight(u8, line, "\r\n");

    // 构建一个回显服务器观察到的内容的响应消息
    var response_storage: [160]u8 = undefined;
    const response = std.fmt.bufPrint(&response_storage, "server observed \"{s}\"\n", .{trimmed}) catch |err| {
        std.debug.print("format failed: {s}\n", .{@errorName(err)});
        return;
    };

    // 使用缓冲写入器将响应发送回客户端
    var outbound_storage: [128]u8 = undefined;
    var net_writer = connection.stream.writer(&outbound_storage);
    net_writer.interface.writeAll(response) catch |err| {
        std.debug.print("write error: {s}\n", .{@errorName(err)});
        return;
    };
    // 确保所有缓冲数据在连接关闭前传输
    net_writer.interface.flush() catch |err| {
        std.debug.print("flush error: {s}\n", .{@errorName(err)});
        return;
    };
}

pub fn main() !void {
    // 初始化分配器以满足动态内存需求
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // 在 127.0.0.1 上创建一个回环服务器，使用操作系统分配的端口（端口 0）
    const address = try std.net.Address.parseIp("127.0.0.1", 0);
    var server = try address.listen(.{ .reuse_address = true });
    defer server.deinit();

    // 创建一个同步原语以协调服务器就绪状态
    var ready = std.Thread.ResetEvent{};
    // 启动服务器线程，该线程将接受并处理一个连接
    const server_thread = try std.Thread.spawn(.{}, serveOne, .{ServerTask{
        .server = &server,
        .ready = &ready,
    }});
    // 确保服务器线程在 main() 退出前完成
    defer server_thread.join();

    // 阻塞直到服务器线程发出已到达 accept() 的信号
    // 这可以防止客户端过早尝试连接的竞态条件
    ready.wait();

    // 检索动态分配的端口号并作为客户端连接
    const port = server.listen_address.in.getPort();
    var stream = try std.net.tcpConnectToHost(allocator, "127.0.0.1", port);
    defer stream.close();

    // 使用缓冲写入器向服务器发送测试消息
    var outbound_storage: [64]u8 = undefined;
    var client_writer = stream.writer(&outbound_storage);
    const payload = "ping over loopback\n";
    try client_writer.interface.writeAll(payload);
    // 强制传输缓冲数据
    try client_writer.interface.flush();

    // 使用缓冲读取器接收服务器的响应
    var inbound_storage: [128]u8 = undefined;
    var client_reader = stream.reader(&inbound_storage);
    const client_reader_iface = client_reader.interface();
    var reply_storage: [128]u8 = undefined;
    const maybe_reply = try readLine(client_reader_iface, &reply_storage);
    const reply = maybe_reply orelse return error.EmptyReply;
    // 移除服务器回复中任何尾随的空白字符
    const trimmed = std.mem.trimRight(u8, reply, "\r\n");

    // 使用缓冲写入器将结果显示到标准输出以提高效率
    var stdout_storage: [256]u8 = undefined;
    var stdout_state = std.fs.File.stdout().writer(&stdout_storage);
    const out = &stdout_state.interface;
    try out.writeAll("loopback handshake succeeded\n");
    try out.print("client received: {s}\n", .{trimmed});
    // 确保在程序退出前所有输出可见
    try out.flush();
}
