const std = @import("std");
const http_request = @import("request.zig");
const http_response = @import("response.zig");
const http_server = @import("server.zig");
const net = std.net;
const os = std.os;
const process = std.process;
const print = std.debug.print;
const assert = std.debug.assert;

const host = .{ 127, 0, 0, 1 };
const port: u16 = 3001;

var http_server_instance: http_server.HttpServer = undefined;

pub fn main() !void {
    var gpa_alloc = std.heap.GeneralPurposeAllocator(.{ .verbose_log = true }){};
    defer assert(gpa_alloc.deinit() == .ok);

    const gpa = gpa_alloc.allocator();

    const act = os.linux.Sigaction{
        .handler = .{ .handler = sigintHandler },
        .mask = os.linux.empty_sigset,
        .flags = 0,
    };

    if (os.linux.sigaction(os.linux.SIG.INT, &act, null) != 0) {
        return error.SignalHandlerError;
    }

    http_server_instance = try http_server.HttpServer.init(gpa, host, port);

    defer http_server_instance.deinit();

    http_server_instance.on_start_listening = onServerStart;
    http_server_instance.on_stop_listening = onServerStop;
    http_server_instance.on_connection_received = onConnectionReceived;
    http_server_instance.on_request = handleRequest;

    try http_server_instance.start();
}

fn handleRequest(response: *http_response.HttpResponse, request: *const http_request.HttpRequest) !void {
    print("Method: {s}\n", .{request.method});
    print("Host: {s}\n", .{request.headers.get("Host") orelse "<none>"});
    print("Body: {s}\n", .{request.body});
    try response.headers.put("X-TEST", "My test");
    response.status_code = 418;
}

fn onServerStart() void {
    print("SERVER - Listening to port: {}\n", .{http_server_instance.port});
}

fn onServerStop() void {
    print("SERVER - Stopping <3\n", .{});
}

fn onConnectionReceived() void {
    print("SERVER - Received a new request\n", .{});
}

fn sigintHandler(_: c_int) callconv(.C) void {
    defer http_server_instance.deinit();
    print("Signt handler\n", .{});
    process.exit(1);
}
