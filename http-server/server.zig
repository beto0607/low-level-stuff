const std = @import("std");
const mem = std.mem;
const net = std.net;
const os = std.os;
const process = std.process;
const print = std.debug.print;
const assert = std.debug.assert;

const host = .{ 127, 0, 0, 1 };
const port: u16 = 3001;

var client: net.Server.Connection = undefined;
var server: net.Server = undefined;

pub fn main() !void {
    var gpa_alloc = std.heap.GeneralPurposeAllocator(.{}){};
    defer assert(gpa_alloc.deinit() == .ok);
    const gpa = gpa_alloc.allocator();

    const address = net.Address.initIp4(host, port);
    server = try address.listen(.{});
    defer server.deinit();

    const act = os.linux.Sigaction{
        .handler = .{ .handler = sigintHandler },
        .mask = os.linux.empty_sigset,
        .flags = 0,
    };

    if (os.linux.sigaction(os.linux.SIG.INT, &act, null) != 0) {
        return error.SignalHandlerError;
    }

    print("Server listenning port: {}\n", .{server.listen_address.getPort()});

    client = try server.accept();
    defer client.stream.close();
    const client_reader = client.stream.reader();

    var request = HttpRequest.init(gpa);
    defer request.free(gpa);

    try ReadRequest(gpa, &request, client_reader);

    print("Method: {s}\n", .{request.method});
    print("Host: {s}\n", .{request.headers.get("Host") orelse "<none>"});
    print("Body: {s}\n", .{request.body});
}

fn sigintHandler(_: c_int) callconv(.C) void {
    client.stream.close();
    server.deinit();
    print("Sign handler\n", .{});
    process.exit(1);
}

const HttpRequest = struct {
    method: []const u8,
    path: []const u8,
    http_version: []const u8,
    content_length: u64,
    body: []const u8,
    // query: []const u8,
    headers: std.StringHashMap([]const u8),
    const Self = @This();

    fn init(gpa: mem.Allocator) Self {
        // self.method = gpa.alloc(u8, 32);
        return .{
            .method = undefined,
            .http_version = undefined,
            .path = undefined,
            .content_length = 0,
            .body = undefined,
            .headers = std.StringHashMap([]const u8).init(gpa),
        };
    }

    fn free(self: *HttpRequest, gpa: mem.Allocator) void {
        gpa.free(self.http_version);
        gpa.free(self.path);
        gpa.free(self.method);
        gpa.free(self.body);
        var headers_iterator = self.headers.iterator();
        while (headers_iterator.next()) |entry| {
            gpa.free(entry.key_ptr.*);
            gpa.free(entry.value_ptr.*);
        }
        self.headers.deinit();
    }
};
const HttpRequestError = error{
    EmptyStartLine,
    ErrorWhileReadingStream,
    InvalidRequest,
};

fn ReadRequest(gpa: mem.Allocator, request: *HttpRequest, reader: net.Stream.Reader) (HttpRequestError)!void {
    const http_start_line = reader.readUntilDelimiterOrEofAlloc(gpa, '\n', 65536) catch return HttpRequestError.ErrorWhileReadingStream;
    if (http_start_line == null) {
        return HttpRequestError.EmptyStartLine;
    }
    defer gpa.free(http_start_line.?);

    print("Start line: {s}\n", .{http_start_line.?});
    parseStartLine(gpa, request, http_start_line.?) catch return HttpRequestError.InvalidRequest;

    parseHeaders(gpa, request, reader) catch return HttpRequestError.InvalidRequest;
    parseBody(gpa, request, reader) catch return HttpRequestError.InvalidRequest;
}

fn parseBody(gpa: mem.Allocator, request: *HttpRequest, reader: net.Stream.Reader) !void {
    const bodyArray: []u8 = try gpa.alloc(u8, request.content_length);
    _ = try reader.read(bodyArray);
    request.body = bodyArray;
}

fn parseHeaders(gpa: mem.Allocator, request: *HttpRequest, reader: net.Stream.Reader) !void {
    var headers = std.StringHashMap([]const u8).init(gpa);

    while (true) {
        const msg = try reader.readUntilDelimiterOrEofAlloc(gpa, '\n', 65536) orelse break;
        defer gpa.free(msg);
        if (msg[0] == '\r') { // end of headers
            break;
        }
        var split_iterator = mem.splitScalar(u8, msg, ':');
        const key = split_iterator.next() orelse return HttpRequestError.InvalidRequest;
        const dupped_key = try dupeChunk(gpa, key);
        const value = split_iterator.rest();
        const dupped_value = try dupeChunk(gpa, value[1 .. value.len - 1]);
        headers.put(dupped_key, dupped_value) catch return HttpRequestError.InvalidRequest;
    }

    request.headers = headers;

    const contentLength = request.headers.get("Content-Length") orelse "0";
    request.content_length = try std.fmt.parseInt(u64, contentLength, 10);
}

fn parseStartLine(gpa: mem.Allocator, request: *HttpRequest, start_line: []const u8) !void {
    var split_iterator = mem.splitScalar(u8, start_line, ' ');

    const method = split_iterator.next() orelse return HttpRequestError.InvalidRequest;
    request.method = try dupeChunk(gpa, method);

    const path = split_iterator.next() orelse return HttpRequestError.InvalidRequest;
    request.path = try dupeChunk(gpa, path);

    const http_version = split_iterator.next() orelse return HttpRequestError.InvalidRequest;
    request.http_version = try dupeChunk(gpa, http_version);
}

fn dupeChunk(gpa: mem.Allocator, chunk: []const u8) ![]const u8 {
    return try gpa.dupe(u8, chunk);
}
