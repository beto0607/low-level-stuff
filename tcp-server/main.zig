const std = @import("std");
const net = std.net;
const print = std.debug.print;

pub fn main() !void {
    var gpa_alloc = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa_alloc.deinit() == .ok);
    const gpa = gpa_alloc.allocator();
    const host = .{ 127, 0, 0, 1 };
    const port: u16 = 3001;

    const address = net.Address.initIp4(host, port);
    var server = try address.listen(.{});
    print("Server listenning port: {}\n", .{server.listen_address.getPort()});

    var client = try server.accept();
    defer client.stream.close();
    print("Client waiting\n", .{});
    const client_reader = client.stream.reader();
    const client_writer = client.stream.writer();
    while (true) {
        const msg = try client_reader.readUntilDelimiterOrEofAlloc(gpa, '\n', 65536) orelse break;
        defer gpa.free(msg);

        std.log.info("Recieved message: \"{}\"", .{std.zig.fmtEscapes(msg)});

        const output_message = "Hello, you filthy animal\n";
        try client_writer.writeAll(output_message);
    }
}
