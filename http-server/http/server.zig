const std = @import("std");
const http_request = @import("request.zig");
const http_response = @import("response.zig");
const mem = std.mem;
const net = std.net;
const print = std.debug.print;
const assert = std.debug.assert;

const OnStartListening = ?*const fn () void;
const OnStopListening = ?*const fn () void;
const OnConnectionReceived = ?*const fn () void;
const OnRequest = ?*const fn (response: *http_response.HttpResponse, request: *const http_request.HttpRequest) anyerror!void;

pub const HttpServer = struct {
    allocator: mem.Allocator,
    client_connection: net.Server.Connection,
    host: [4]u8,
    port: u16,
    server: net.Server,

    on_start_listening: OnStartListening,
    on_stop_listening: OnStartListening,
    on_connection_received: OnConnectionReceived,
    on_request: OnRequest,

    const Self = @This();

    pub fn init(allocator: mem.Allocator, host: [4]u8, port: u16) !Self {
        return .{
            .allocator = allocator,
            .client_connection = undefined,
            .host = host,
            .on_start_listening = undefined,
            .on_stop_listening = undefined,
            .on_connection_received = undefined,
            .port = port,
            .server = undefined,
            .on_request = undefined,
        };
    }

    pub fn deinit(self: *Self) void {
        self.server.deinit();
    }

    pub fn start(self: *Self) !void {
        const address = net.Address.initIp4(self.host, self.port);
        self.server = try address.listen(.{ .reuse_address = true });

        if (self.on_start_listening) |callback| {
            callback();
        }

        var arena = std.heap.ArenaAllocator.init(self.allocator);
        defer arena.deinit();

        var number_of_requests: u8 = 0;
        while (number_of_requests < 1) {
            number_of_requests += 1;
            const allocator = arena.allocator();

            self.client_connection = try self.server.accept();
            defer self.client_connection.stream.close();

            if (self.on_connection_received) |callback| {
                callback();
            }

            const client_reader = self.client_connection.stream.reader();

            var request = http_request.HttpRequest.init();

            try http_request.ReadRequest(allocator, &request, client_reader);
            const request_obj: *const http_request.HttpRequest = &request;

            const client_writer = self.client_connection.stream.writer();
            var response = http_response.HttpResponse.init(allocator);
            defer response.deinit();

            response.status_code = 204;

            if (self.on_request) |handler| {
                try handler(&response, request_obj);
            }

            try response.headers.put("Server", "My cool server");
            // try response.headers.put("Date", "Wed, 26 Jun 2024 12:00:00 GMT");
            // try response.headers.put("Content-Type", "text/html; charset=UTF-8");
            try response.headers.put("Content-Length", "0");
            // try response.headers.put("Location", "http://localhost:3001/test");

            try response.write(client_writer);
        }

        if (self.on_stop_listening) |callback| {
            callback();
        }
    }
};
