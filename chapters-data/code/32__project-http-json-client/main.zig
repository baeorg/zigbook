const std = @import("std");

// 模拟包含多个区域服务健康数据的JSON响应。
// 在真实应用中，这会来自实际的API端点。
const summary_payload =
    "{\n" ++ "  \"regions\": [\n" ++ "    {\n" ++ "      \"name\": \"us-east\",\n" ++ "      \"uptime\": 0.99983,\n" ++ "      \"services\": [\n" ++ "        {\"name\":\"auth\",\"state\":\"up\",\"latency_ms\":2.7},\n" ++ "        {\"name\":\"billing\",\"state\":\"degraded\",\"latency_ms\":184.0},\n" ++ "        {\"name\":\"search\",\"state\":\"up\",\"latency_ms\":5.1}\n" ++ "      ],\n" ++ "      \"incidents\": [\n" ++ "        {\"kind\":\"maintenance\",\"window_start\":\"2025-11-06T01:00Z\",\"expected_minutes\":45}\n" ++ "      ]\n" ++ "    },\n" ++ "    {\n" ++ "      \"name\": \"eu-central\",\n" ++ "      \"uptime\": 0.99841,\n" ++ "      \"services\": [\n" ++ "        {\"name\":\"auth\",\"state\":\"up\",\"latency_ms\":3.1},\n" ++ "        {\"name\":\"billing\",\"state\":\"outage\",\"latency_ms\":0.0}\n" ++ "      ],\n" ++ "      \"incidents\": [\n" ++ "        {\"kind\":\"outage\",\"started\":\"2025-11-05T08:12Z\",\"severity\":\"critical\"}\n" ++ "      ]\n" ++ "    }\n" ++ "  ]\n" ++ "}\n";

// 协调结构，用于在线程之间传递服务器状态。
// ResetEvent使主线程能够等待直到服务器准备好接受连接。
const ServerTask = struct {
    server: *std.net.Server,
    ready: *std.Thread.ResetEvent,
};

// 在后台线程上运行最小HTTP服务器fixture。
// 使用上面的JSON有效负载响应/api/status，
// 对所有其他路径返回404。
fn serveStatus(task: ServerTask) void {
    // 向主线程发出服务器正在监听且已准备好的信号。
    task.ready.set();

    const connection = task.server.accept() catch |err| {
        std.log.err("accept failed: {s}", .{@errorName(err)});
        return;
    };
    defer connection.stream.close();

    // 为HTTP协议I/O分配固定缓冲区。
    // Reader和Writer接口包装这些缓冲区以管理状态。
    var recv_buf: [4096]u8 = undefined;
    var send_buf: [4096]u8 = undefined;
    var reader = connection.stream.reader(&recv_buf);
    var writer = connection.stream.writer(&send_buf);
    var server = std.http.Server.init(reader.interface(), &writer.interface);

    // 处理传入请求直到连接关闭。
    while (server.reader.state == .ready) {
        var request = server.receiveHead() catch |err| switch (err) {
            error.HttpConnectionClosing => return,
            else => {
                std.log.err("receive head failed: {s}", .{@errorName(err)});
                return;
            },
        };

        // 基于请求目标（路径）路由。
        if (std.mem.eql(u8, request.head.target, "/api/status")) {
            request.respond(summary_payload, .{
                .extra_headers = &.{
                    .{ .name = "content-type", .value = "application/json" },
                },
            }) catch |err| {
                std.log.err("respond failed: {s}", .{@errorName(err)});
                return;
            };
        } else {
            request.respond("not found\n", .{
                .status = .not_found,
                .extra_headers = &.{
                    .{ .name = "content-type", .value = "text/plain" },
                },
            }) catch |err| {
                std.log.err("respond failed: {s}", .{@errorName(err)});
                return;
            };
        }
    }
}

// 表示服务健康数据最终类型化结构的域模型。
// 所有切片都由与请求生命周期绑定的arena分配器拥有。
const Summary = struct {
    regions: []Region,
};

const Region = struct {
    name: []const u8,
    uptime: f64,
    services: []Service,
    incidents: []Incident,
};

const Service = struct {
    name: []const u8,
    state: ServiceState,
    latency_ms: f64,
};

const ServiceState = enum { up, degraded, outage };

// 标记联合模型化两种事件。
// 每个变体都携带自己的有效负载结构。
const Incident = union(enum) {
    maintenance: Maintenance,
    outage: Outage,
};

const Maintenance = struct {
    window_start: []const u8,
    expected_minutes: u32,
};

const Outage = struct {
    started: []const u8,
    severity: Severity,
};

const Severity = enum { info, warning, critical };

// 线性格式结构完全镜像JSON形状。
// 所有字段都是可选的，以匹配宽松的JSON模式；
// 我们在验证后将它们提升为类型化域模型。
const SummaryWire = struct {
    regions: []RegionWire,
};

const RegionWire = struct {
    name: []const u8,
    uptime: f64,
    services: []ServiceWire,
    incidents: []IncidentWire,
};

const ServiceWire = struct {
    name: []const u8,
    state: []const u8,
    latency_ms: f64,
};

// 所有事件字段都是可选的，因为不同的事件类型使用不同的字段。
const IncidentWire = struct {
    kind: []const u8,
    window_start: ?[]const u8 = null,
    expected_minutes: ?u32 = null,
    started: ?[]const u8 = null,
    severity: ?[]const u8 = null,
};

// 解码和验证失败的自定义错误集。
const DecodeError = error{
    UnknownServiceState,
    UnknownIncidentKind,
    UnknownSeverity,
    MissingField,
};

// 在目标分配器中分配输入切片的副本。
// 用于将JSON字符串的所有权从解析器的临时缓冲区
// 传输到arena分配器，以便它们在解析完成后保持有效。
fn dupeSlice(allocator: std.mem.Allocator, bytes: []const u8) ![]const u8 {
    const copy = try allocator.alloc(u8, bytes.len);
    @memcpy(copy, bytes);
    return copy;
}

// 将服务状态字符串映射到相应的枚举变体。
// 不区分大小写以处理JSON格式的变化。
fn parseServiceState(text: []const u8) DecodeError!ServiceState {
    if (std.ascii.eqlIgnoreCase(text, "up")) return .up;
    if (std.ascii.eqlIgnoreCase(text, "degraded")) return .degraded;
    if (std.ascii.eqlIgnoreCase(text, "outage")) return .outage;
    return error.UnknownServiceState;
}

// 将严重性字符串解析为Severity枚举。
fn parseSeverity(text: []const u8) DecodeError!Severity {
    if (std.ascii.eqlIgnoreCase(text, "info")) return .info;
    if (std.ascii.eqlIgnoreCase(text, "warning")) return .warning;
    if (std.ascii.eqlIgnoreCase(text, "critical")) return .critical;
    return error.UnknownSeverity;
}

// 将线性格式数据提升为类型化域模型。
// 验证必需字段、解析枚举，并将字符串复制到arena中。
// 所有分配都使用arena，因此当arena被释放时清理是自动的。
fn buildSummary(
    arena: std.mem.Allocator,
    parsed: SummaryWire,
) (DecodeError || std.mem.Allocator.Error)!Summary {
    const regions = try arena.alloc(Region, parsed.regions.len);
    for (parsed.regions, regions) |wire, *region| {
        region.name = try dupeSlice(arena, wire.name);
        region.uptime = wire.uptime;

        // 将每个服务从线性格式转换为类型化模型。
        region.services = try arena.alloc(Service, wire.services.len);
        for (wire.services, region.services) |service_wire, *service| {
            service.name = try dupeSlice(arena, service_wire.name);
            service.state = try parseServiceState(service_wire.state);
            service.latency_ms = service_wire.latency_ms;
        }

        // 基于`kind`字段将事件提升到标记联合中。
        region.incidents = try arena.alloc(Incident, wire.incidents.len);
        for (wire.incidents, region.incidents) |incident_wire, *incident| {
            if (std.ascii.eqlIgnoreCase(incident_wire.kind, "maintenance")) {
                const window_start = incident_wire.window_start orelse return error.MissingField;
                const expected = incident_wire.expected_minutes orelse return error.MissingField;
                incident.* = .{ .maintenance = .{
                    .window_start = try dupeSlice(arena, window_start),
                    .expected_minutes = expected,
                } };
            } else if (std.ascii.eqlIgnoreCase(incident_wire.kind, "outage")) {
                const started = incident_wire.started orelse return error.MissingField;
                const severity_text = incident_wire.severity orelse return error.MissingField;
                const severity = try parseSeverity(severity_text);
                incident.* = .{ .outage = .{
                    .started = try dupeSlice(arena, started),
                    .severity = severity,
                } };
            } else {
                return error.UnknownIncidentKind;
            }
        }
    }

    return .{ .regions = regions };
}

// 通过HTTP获取状态端点并将JSON响应解码为Summary。
// 为HTTP响应使用固定缓冲区；对于更大的有效负载，切换到流式方法。
fn fetchSummary(arena: std.mem.Allocator, client: *std.http.Client, url: []const u8) !Summary {
    var response_buffer: [4096]u8 = undefined;
    var response_writer = std.Io.Writer.fixed(response_buffer[0..]);

    // 使用自定义User-Agent头执行HTTP获取。
    const result = try client.fetch(.{
        .location = .{ .url = url },
        .response_writer = &response_writer,
        .headers = .{
            .user_agent = .{ .override = "zigbook-http-json-client/0.1" },
        },
    });
    _ = result;

    // 从固定写入器的缓冲区提取响应体。
    const body = response_writer.buffer[0..response_writer.end];

    // 将JSON解析为线性格式结构。
    var parsed = try std.json.parseFromSlice(SummaryWire, arena, body, .{});
    defer parsed.deinit();

    // 将线性格式提升为类型化域模型。
    return buildSummary(arena, parsed.value);
}

// 将服务摘要呈现为格式化表格，后跟事件列表。
// 使用缓冲写入器高效输出到stdout。
fn renderSummary(summary: Summary) !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const out = &stdout_writer.interface;

    // 打印服务表头。
    try out.writeAll("SERVICE SUMMARY\n");
    try out.writeAll("Region        Service        State       Latency (ms)\n");
    try out.writeAll("-----------------------------------------------------\n");

    // 按区域分组打印每个服务。
    for (summary.regions) |region| {
        for (region.services) |service| {
            try out.print("{s:<13}{s:<14}{s:<12}{d:7.1}\n", .{
                region.name,
                service.name,
                @tagName(service.state),
                service.latency_ms,
            });
        }
    }

    // 打印事件节标题。
    try out.writeAll("\nACTIVE INCIDENTS\n");
    var incident_count: usize = 0;

    // 迭代所有区域的所有事件并基于类型进行格式化。
    for (summary.regions) |region| {
        for (region.incidents) |incident| {
            incident_count += 1;
            switch (incident) {
                .maintenance => |m| try out.print("- {s}: maintenance window starts {s}, {d} min\n", .{
                    region.name,
                    m.window_start,
                    m.expected_minutes,
                }),
                .outage => |o| try out.print("- {s}: outage since {s} (severity: {s})\n", .{
                    region.name,
                    o.started,
                    @tagName(o.severity),
                }),
            }
        }
    }

    if (incident_count == 0) {
        try out.writeAll("- No active incidents reported.\n");
    }

    try out.writeAll("\n");
    try out.flush();
}

pub fn main() !void {
    // 为长期分配（客户端、服务器）设置通用分配器。
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // 绑定到本地主机的OS分配端口（port 0 → 自动选择）。
    const address = try std.net.Address.parseIp("127.0.0.1", 0);
    var server = try address.listen(.{ .reuse_address = true });
    defer server.deinit();

    // 在后台线程上启动服务器fixture。
    var ready = std.Thread.ResetEvent{};
    const server_thread = try std.Thread.spawn(.{}, serveStatus, .{ServerTask{
        .server = &server,
        .ready = &ready,
    }});
    defer server_thread.join();

    // 等待服务器线程发出它准备好接受连接的信号。
    ready.wait();

    // 检索OS选择的实际端口。
    const port = server.listen_address.in.getPort();

    // 使用主分配器初始化HTTP客户端。
    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();

    // 为所有解析的数据创建arena分配器。
    // arena拥有Summary中的所有切片；当arena被销毁时它们被释放。
    var arena_inst = std.heap.ArenaAllocator.init(allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();

    // 设置缓冲stdout用于记录。
    var stdout_buffer: [256]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const log_out = &stdout_writer.interface;

    // 构造具有动态分配端口的完整URL。
    var url_buffer: [128]u8 = undefined;
    const url = try std.fmt.bufPrint(&url_buffer, "http://127.0.0.1:{d}/api/status", .{port});
    try log_out.print("Fetching {s}...\n", .{url});

    // 获取和解码状态端点。
    const summary = try fetchSummary(arena, &client, url);
    try log_out.print("Parsed {d} regions.\n\n", .{summary.regions.len});
    try log_out.flush();

    // 将最终报告呈现到stdout。
    try renderSummary(summary);
}
