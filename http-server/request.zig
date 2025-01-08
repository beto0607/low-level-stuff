const std = @import("std");
const mem = std.mem;
const net = std.net;
const print = std.debug.print;

pub const HttpRequest = struct {
    method: []const u8,
    path: []const u8,
    http_version: []const u8,
    content_length: u64,
    body: []const u8,
    // query: []const u8,
    headers: std.StringHashMap([]const u8),
    const Self = @This();

    pub fn init(allocator: mem.Allocator) Self {
        return .{
            .method = undefined,
            .http_version = undefined,
            .path = undefined,
            .content_length = 0,
            .body = undefined,
            .headers = std.StringHashMap([]const u8).init(allocator),
        };
    }
};

pub const HttpRequestError = error{
    EmptyStartLine,
    ErrorWhileReadingStream,
    InvalidRequest,
};

pub fn ReadRequest(allocator: mem.Allocator, request: *HttpRequest, reader: net.Stream.Reader) (HttpRequestError)!void {
    const http_start_line = reader.readUntilDelimiterOrEofAlloc(allocator, '\n', 65536) catch return HttpRequestError.ErrorWhileReadingStream;
    if (http_start_line == null) {
        return HttpRequestError.EmptyStartLine;
    }
    defer allocator.free(http_start_line.?);

    print("Start line: {s}\n", .{http_start_line.?});
    parseStartLine(allocator, request, http_start_line.?) catch return HttpRequestError.InvalidRequest;

    parseHeaders(allocator, request, reader) catch return HttpRequestError.InvalidRequest;
    parseBody(allocator, request, reader) catch return HttpRequestError.InvalidRequest;
}

fn parseBody(allocator: mem.Allocator, request: *HttpRequest, reader: net.Stream.Reader) !void {
    const bodyArray: []u8 = try allocator.alloc(u8, request.content_length);
    _ = try reader.read(bodyArray);
    request.body = bodyArray;
}

fn parseHeaders(allocator: mem.Allocator, request: *HttpRequest, reader: net.Stream.Reader) !void {
    var headers = std.StringHashMap([]const u8).init(allocator);

    while (true) {
        const msg = try reader.readUntilDelimiterOrEofAlloc(allocator, '\n', 65536) orelse break;
        defer allocator.free(msg);
        if (msg[0] == '\r') { // end of headers
            break;
        }
        var split_iterator = mem.splitScalar(u8, msg, ':');
        const key = split_iterator.next() orelse return HttpRequestError.InvalidRequest;
        const dupped_key = try allocator.dupe(u8, key);
        const value = split_iterator.rest();
        const dupped_value = try allocator.dupe(u8, value[1 .. value.len - 1]);
        headers.put(dupped_key, dupped_value) catch return HttpRequestError.InvalidRequest;
    }

    request.headers = headers;

    const contentLength = request.headers.get("Content-Length") orelse "0";
    request.content_length = try std.fmt.parseInt(u64, contentLength, 10);
}

fn parseStartLine(allocator: mem.Allocator, request: *HttpRequest, start_line: []const u8) !void {
    var split_iterator = mem.splitScalar(u8, start_line, ' ');

    const method = split_iterator.next() orelse return HttpRequestError.InvalidRequest;
    request.method = try allocator.dupe(u8, method);

    const path = split_iterator.next() orelse return HttpRequestError.InvalidRequest;
    request.path = try allocator.dupe(u8, path);

    const http_version = split_iterator.next() orelse return HttpRequestError.InvalidRequest;
    request.http_version = try allocator.dupe(u8, http_version);
}
