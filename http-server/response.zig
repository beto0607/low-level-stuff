const std = @import("std");
const mem = std.mem;
const net = std.net;
const fmt = std.fmt;
const print = std.debug.print;

pub const HttpResponse = struct {
    http_version: []const u8,
    status_code: u10,
    headers: std.StringHashMap([]const u8),
    body: []u8,

    allocator: mem.Allocator,

    const Self = @This();

    pub fn init(gpa: mem.Allocator) Self {
        return .{
            .http_version = "HTTP/1.1",
            .status_code = 200,
            .headers = std.StringHashMap([]const u8).init(gpa),
            .body = &[_]u8{},
            .allocator = gpa,
        };
    }

    pub fn free(self: *HttpResponse, gpa: mem.Allocator) void {
        gpa.free(self.body);
        self.headers.deinit();
    }

    pub fn write(self: *HttpResponse, writer: net.Stream.Writer) !void {
        try self.writeStartLine(writer);
        try self.writeHeaders(writer);
        _ = try writer.writeAll("\n");
        _ = try writer.writeAll(self.body);
    }

    fn writeHeaders(self: *HttpResponse, writer: net.Stream.Writer) !void {
        var iterator = self.headers.iterator();
        while (iterator.next()) |entry| {
            const header_line = try fmt.allocPrint(self.allocator, "{s}: {s}\n", .{ entry.key_ptr.*, entry.value_ptr.* });
            try writer.writeAll(header_line);
            self.allocator.free(header_line);
        }
    }

    fn writeStartLine(self: *HttpResponse, writer: net.Stream.Writer) !void {
        const status_message = self.getStatusMessage();
        const start_line = try fmt.allocPrint(
            self.allocator,
            "{s} {d} {s}\n",
            .{
                self.http_version,
                self.status_code,
                status_message,
            },
        );
        defer self.allocator.free(start_line);
        try writer.writeAll(start_line);
    }

    fn getStatusMessage(self: *HttpResponse) []const u8 {
        switch (self.status_code) {
            100 => return "Continue",
            101 => return "Switching Protocols",
            102 => return "Processing",
            103 => return "Early Hints",
            200 => return "OK",
            201 => return "Created",
            202 => return "Accepted",
            203 => return "Non-Authoritative Information",
            204 => return "No Content",
            205 => return "Reset Content",
            206 => return "Partial Content",
            207 => return "Multi-Status",
            208 => return "Already Reported",
            226 => return "IM Used",
            300 => return "Multiple Choices",
            301 => return "Moved Permanently",
            302 => return "Found",
            303 => return "See Other",
            304 => return "Not Modified",
            307 => return "Temporary Redirect",
            308 => return "Permanent Redirect",
            400 => return "Bad Request",
            401 => return "Unauthorized",
            402 => return "Payment Required",
            403 => return "Forbidden",
            404 => return "Not Found",
            405 => return "Method Not Allowed",
            406 => return "Not Acceptable",
            407 => return "Proxy Authentication Required",
            408 => return "Request Timeout",
            409 => return "Conflict",
            410 => return "Gone",
            411 => return "Length Required",
            412 => return "Precondition Failed",
            413 => return "Content Too Large",
            414 => return "URI Too Long",
            415 => return "Unsupported Media Type",
            416 => return "Range Not Satisfiable",
            417 => return "Expectation Failed",
            418 => return "I'm a teapot",
            421 => return "Misdirected Request",
            422 => return "Unprocessable Content",
            423 => return "Locked",
            424 => return "Failed Dependency",
            425 => return "Too Early",
            426 => return "Upgrade Required",
            428 => return "Precondition Required",
            429 => return "Too Many Requests",
            431 => return "Request Header Fields Too Large",
            451 => return "Unavailable For Legal Reasons",
            500 => return "Internal Server Error",
            501 => return "Not Implemented",
            502 => return "Bad Gateway",
            503 => return "Service Unavailable",
            504 => return "Gateway Timeout",
            505 => return "HTTP Version Not Supported",
            506 => return "Variant Also Negotiates",
            507 => return "Insufficient Storage",
            508 => return "Loop Detected",
            510 => return "Not Extended",
            511 => return "Network Authentication Required",
            else => return "Unknown",
        }
    }
};
