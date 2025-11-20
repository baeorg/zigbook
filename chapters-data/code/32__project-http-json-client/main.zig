const std = @import("std");

// Mock JSON response containing service health data for multiple regions.
// Mock JSON response containing service health 数据 用于 multiple regions.
// In a real application, this would come from an actual API endpoint.
// 在 一个 real application, 此 would come 从 一个 actual API endpoint.
const summary_payload =
    "{\n" ++ "  \"regions\": [\n" ++ "    {\n" ++ "      \"name\": \"us-east\",\n" ++ "      \"uptime\": 0.99983,\n" ++ "      \"services\": [\n" ++ "        {\"name\":\"auth\",\"state\":\"up\",\"latency_ms\":2.7},\n" ++ "        {\"name\":\"billing\",\"state\":\"degraded\",\"latency_ms\":184.0},\n" ++ "        {\"name\":\"search\",\"state\":\"up\",\"latency_ms\":5.1}\n" ++ "      ],\n" ++ "      \"incidents\": [\n" ++ "        {\"kind\":\"maintenance\",\"window_start\":\"2025-11-06T01:00Z\",\"expected_minutes\":45}\n" ++ "      ]\n" ++ "    },\n" ++ "    {\n" ++ "      \"name\": \"eu-central\",\n" ++ "      \"uptime\": 0.99841,\n" ++ "      \"services\": [\n" ++ "        {\"name\":\"auth\",\"state\":\"up\",\"latency_ms\":3.1},\n" ++ "        {\"name\":\"billing\",\"state\":\"outage\",\"latency_ms\":0.0}\n" ++ "      ],\n" ++ "      \"incidents\": [\n" ++ "        {\"kind\":\"outage\",\"started\":\"2025-11-05T08:12Z\",\"severity\":\"critical\"}\n" ++ "      ]\n" ++ "    }\n" ++ "  ]\n" ++ "}\n";

// Coordination structure for passing server state between threads.
// Coordination structure 用于 passing server state between threads.
// The ResetEvent enables the main thread to wait until the server is ready to accept connections.
// ResetEvent enables 主 thread 到 wait until server is ready 到 accept connections.
const ServerTask = struct {
    server: *std.net.Server,
    ready: *std.Thread.ResetEvent,
};

// Runs a minimal HTTP server fixture on a background thread.
// Runs 一个 最小化 HTTP server fixture 在 一个 background thread.
// Responds to /api/status with the canned JSON payload above,
// Responds 到 /api/状态 使用 canned JSON 载荷 above,
// and returns 404 for all other paths.
// 和 返回 404 用于 所有 other 路径.
fn serveStatus(task: ServerTask) void {
    // Signal to the main thread that the server is listening and ready.
    // Signal 到 主 thread 该 server is listening 和 ready.
    task.ready.set();

    const connection = task.server.accept() catch |err| {
        std.log.err("accept failed: {s}", .{@errorName(err)});
        return;
    };
    defer connection.stream.close();

    // Allocate fixed buffers for HTTP protocol I/O.
    // 分配 fixed buffers 用于 HTTP protocol I/O.
    // The Reader and Writer interfaces wrap these buffers to manage state.
    // Reader 和 Writer interfaces wrap 这些 buffers 到 manage state.
    var recv_buf: [4096]u8 = undefined;
    var send_buf: [4096]u8 = undefined;
    var reader = connection.stream.reader(&recv_buf);
    var writer = connection.stream.writer(&send_buf);
    var server = std.http.Server.init(reader.interface(), &writer.interface);

    // Handle incoming requests until the connection closes.
    // 处理 incoming requests until connection closes.
    while (server.reader.state == .ready) {
        var request = server.receiveHead() catch |err| switch (err) {
            error.HttpConnectionClosing => return,
            else => {
                std.log.err("receive head failed: {s}", .{@errorName(err)});
                return;
            },
        };

        // Route based on request target (path).
        // Route 基于 request target (路径).
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

// Domain model representing the final, typed structure of the service health data.
// Domain model representing 最终, typed structure 的 service health 数据.
// All slices are owned by an arena allocator tied to the request lifetime.
// 所有 slices are owned 通过 一个 arena allocator tied 到 request lifetime.
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

// Tagged union modeling the two kinds of incidents.
// Tagged union modeling 两个 kinds 的 incidents.
// Each variant carries its own payload structure.
// 每个 variant carries its own 载荷 structure.
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

// Wire format structures mirror the JSON shape exactly.
// Wire format structures mirror JSON shape exactly.
// All fields are optional to match the loose JSON schema;
// 所有 fields are 可选 到 match loose JSON schema;
// we promote them to the typed domain model after validation.
// we promote them 到 typed domain model after validation.
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

// All incident fields are optional because different incident kinds use different fields.
// 所有 incident fields are 可选 because different incident kinds use different fields.
const IncidentWire = struct {
    kind: []const u8,
    window_start: ?[]const u8 = null,
    expected_minutes: ?u32 = null,
    started: ?[]const u8 = null,
    severity: ?[]const u8 = null,
};

// Custom error set for decoding and validation failures.
// 自定义 错误集合 用于 decoding 和 validation failures.
const DecodeError = error{
    UnknownServiceState,
    UnknownIncidentKind,
    UnknownSeverity,
    MissingField,
};

// Allocates a copy of the input slice in the target allocator.
// 分配 一个 复制 的 输入 切片 在 target allocator.
// Used to transfer ownership of JSON strings from the parser's temporary buffers
// Used 到 transfer ownership 的 JSON 字符串 从 parser's temporary buffers
// into the arena allocator so they remain valid after parsing completes.
// into arena allocator so they remain valid after 解析 completes.
fn dupeSlice(allocator: std.mem.Allocator, bytes: []const u8) ![]const u8 {
    const copy = try allocator.alloc(u8, bytes.len);
    @memcpy(copy, bytes);
    return copy;
}

// Maps a service state string to the corresponding enum variant.
// Maps 一个 service state string 到 对应的 enum variant.
// Case-insensitive to handle variations in JSON formatting.
// Case-insensitive 到 处理 variations 在 JSON formatting.
fn parseServiceState(text: []const u8) DecodeError!ServiceState {
    if (std.ascii.eqlIgnoreCase(text, "up")) return .up;
    if (std.ascii.eqlIgnoreCase(text, "degraded")) return .degraded;
    if (std.ascii.eqlIgnoreCase(text, "outage")) return .outage;
    return error.UnknownServiceState;
}

// Parses severity strings into the Severity enum.
// Parses severity 字符串 into Severity enum.
fn parseSeverity(text: []const u8) DecodeError!Severity {
    if (std.ascii.eqlIgnoreCase(text, "info")) return .info;
    if (std.ascii.eqlIgnoreCase(text, "warning")) return .warning;
    if (std.ascii.eqlIgnoreCase(text, "critical")) return .critical;
    return error.UnknownSeverity;
}

// Promotes wire format data into the typed domain model.
// Promotes wire format 数据 into typed domain model.
// Validates required fields, parses enums, and copies strings into the arena.
// Validates 必需 fields, parses enums, 和 copies 字符串 into arena.
// All allocations use the arena so cleanup is automatic when the arena is freed.
// 所有 allocations use arena so cleanup is automatic 当 arena is freed.
fn buildSummary(
    arena: std.mem.Allocator,
    parsed: SummaryWire,
) (DecodeError || std.mem.Allocator.Error)!Summary {
    const regions = try arena.alloc(Region, parsed.regions.len);
    for (parsed.regions, regions) |wire, *region| {
        region.name = try dupeSlice(arena, wire.name);
        region.uptime = wire.uptime;

        // Convert each service from wire format to typed model.
        // Convert 每个 service 从 wire format 到 typed model.
        region.services = try arena.alloc(Service, wire.services.len);
        for (wire.services, region.services) |service_wire, *service| {
            service.name = try dupeSlice(arena, service_wire.name);
            service.state = try parseServiceState(service_wire.state);
            service.latency_ms = service_wire.latency_ms;
        }

        // Promote incidents into the tagged union based on the `kind` field.
        // Promote incidents into tagged union 基于 `kind` field.
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

// Fetches the status endpoint via HTTP and decodes the JSON response into a Summary.
// Fetches 状态 endpoint via HTTP 和 decodes JSON response into 一个 Summary.
// Uses a fixed buffer for the HTTP response; for larger payloads, switch to a streaming approach.
// 使用 一个 fixed 缓冲区 用于 HTTP response; 用于 larger payloads, switch 到 一个 streaming approach.
fn fetchSummary(arena: std.mem.Allocator, client: *std.http.Client, url: []const u8) !Summary {
    var response_buffer: [4096]u8 = undefined;
    var response_writer = std.Io.Writer.fixed(response_buffer[0..]);

    // Perform the HTTP fetch with a custom User-Agent header.
    // 执行 HTTP fetch 使用 一个 自定义 User-Agent header.
    const result = try client.fetch(.{
        .location = .{ .url = url },
        .response_writer = &response_writer,
        .headers = .{
            .user_agent = .{ .override = "zigbook-http-json-client/0.1" },
        },
    });
    _ = result;

    // Extract the response body from the fixed writer's buffer.
    // Extract response body 从 fixed writer's 缓冲区.
    const body = response_writer.buffer[0..response_writer.end];
    
    // Parse JSON into the wire format structures.
    // Parse JSON into wire format structures.
    var parsed = try std.json.parseFromSlice(SummaryWire, arena, body, .{});
    defer parsed.deinit();

    // Promote wire format to typed domain model.
    // Promote wire format 到 typed domain model.
    return buildSummary(arena, parsed.value);
}

// Renders the service summary as a formatted table followed by an incident list.
// Renders service summary 作为 一个 格式化 table followed 通过 一个 incident list.
// Uses a buffered writer for efficient output to stdout.
// 使用 一个 缓冲写入器 用于 efficient 输出 到 stdout.
fn renderSummary(summary: Summary) !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const out = &stdout_writer.interface;

    // Print service table header.
    // 打印 service table header.
    try out.writeAll("SERVICE SUMMARY\n");
    try out.writeAll("Region        Service        State       Latency (ms)\n");
    try out.writeAll("-----------------------------------------------------\n");
    
    // Print each service, grouped by region.
    // 打印 每个 service, grouped 通过 region.
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

    // Print incident section header.
    // 打印 incident 节 header.
    try out.writeAll("\nACTIVE INCIDENTS\n");
    var incident_count: usize = 0;
    
    // Iterate all incidents across all regions and format based on kind.
    // 迭代 所有 incidents across 所有 regions 和 format 基于 kind.
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
    // Set up a general-purpose allocator for long-lived allocations (client, server).
    // Set up 一个 general-purpose allocator 用于 long-lived allocations (client, server).
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Bind to localhost on an OS-assigned port (port 0 → automatic selection).
    // Bind 到 localhost 在 一个 OS-assigned port (port 0 → automatic selection).
    const address = try std.net.Address.parseIp("127.0.0.1", 0);
    var server = try address.listen(.{ .reuse_address = true });
    defer server.deinit();

    // Spin up the server fixture on a background thread.
    // Spin up server fixture 在 一个 background thread.
    var ready = std.Thread.ResetEvent{};
    const server_thread = try std.Thread.spawn(.{}, serveStatus, .{ServerTask{
        .server = &server,
        .ready = &ready,
    }});
    defer server_thread.join();

    // Wait for the server thread to signal that it's ready to accept connections.
    // Wait 用于 server thread 到 signal 该 it's ready 到 accept connections.
    ready.wait();

    // Retrieve the actual port chosen by the OS.
    // Retrieve actual port chosen 通过 OS.
    const port = server.listen_address.in.getPort();

    // Initialize the HTTP client with the main allocator.
    // Initialize HTTP client 使用 主 allocator.
    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();

    // Create an arena allocator for all parsed data.
    // 创建 一个 arena allocator 用于 所有 parsed 数据.
    // The arena owns all slices in the Summary; they're freed when the arena is destroyed.
    // arena owns 所有 slices 在 Summary; they're freed 当 arena is destroyed.
    var arena_inst = std.heap.ArenaAllocator.init(allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();

    // Set up buffered stdout for logging.
    // Set up 缓冲 stdout 用于 logging.
    var stdout_buffer: [256]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const log_out = &stdout_writer.interface;

    // Construct the full URL with the dynamically assigned port.
    // Construct 满 URL 使用 dynamically assigned port.
    var url_buffer: [128]u8 = undefined;
    const url = try std.fmt.bufPrint(&url_buffer, "http://127.0.0.1:{d}/api/status", .{port});
    try log_out.print("Fetching {s}...\n", .{url});

    // Fetch and decode the status endpoint.
    // Fetch 和 decode 状态 endpoint.
    const summary = try fetchSummary(arena, &client, url);
    try log_out.print("Parsed {d} regions.\n\n", .{summary.regions.len});
    try log_out.flush();

    // Render the final report to stdout.
    // Render 最终 report 到 stdout.
    try renderSummary(summary);
}
