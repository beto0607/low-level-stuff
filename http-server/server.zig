const std = @import("std");
const http_request = @import("request.zig");
const http_response = @import("response.zig");
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
    var arena = std.heap.ArenaAllocator.init(gpa_alloc.allocator());
    defer arena.deinit();
    const allocator = arena.allocator();

    const act = os.linux.Sigaction{
        .handler = .{ .handler = sigintHandler },
        .mask = os.linux.empty_sigset,
        .flags = 0,
    };

    if (os.linux.sigaction(os.linux.SIG.INT, &act, null) != 0) {
        return error.SignalHandlerError;
    }

    const address = net.Address.initIp4(host, port);
    server = try address.listen(.{});
    defer server.deinit();

    print("Server listenning port: {}\n", .{server.listen_address.getPort()});

    client = try server.accept();
    defer client.stream.close();
    const client_reader = client.stream.reader();

    var request = http_request.HttpRequest.init(allocator);

    try http_request.ReadRequest(allocator, &request, client_reader);

    print("Method: {s}\n", .{request.method});
    print("Host: {s}\n", .{request.headers.get("Host") orelse "<none>"});
    print("Body: {s}\n", .{request.body});

    const client_writer = client.stream.writer();
    var response = http_response.HttpResponse.init(allocator);

    response.status_code = 204;
    try response.headers.put("Server", "My cool server");
    // try response.headers.put("Date", "Wed, 26 Jun 2024 12:00:00 GMT");
    try response.headers.put("Content-Type", "text/html; charset=UTF-8");
    try response.headers.put("Content-Length", "0");
    try response.headers.put("Location", "http://localhost:3001/test");

    try response.write(client_writer);
}

fn sigintHandler(_: c_int) callconv(.C) void {
    client.stream.close();
    server.deinit();
    print("Sign handler\n", .{});
    process.exit(1);
}
