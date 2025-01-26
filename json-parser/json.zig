const std = @import("std");
const mem = std.mem;
const fs = std.fs;
const io = std.io;
const print = std.debug.print;

const JSONObject = struct {};

pub fn parseFileReader(allocator: mem.Allocator, stream: io.AnyReader) !void {
    var on_string = false;
    var current_string = std.ArrayList(u8).init(allocator);
    while (true) {
        const byte = stream.readByte() catch break;

        if (on_string) {
            if (byte == '"') {
                on_string = false;
                continue;
            }
            current_string.append(byte);
        }
        if (byte == '"') {
            on_string = true;
        }

        print("{c}", .{byte});
    }
    print("\n", .{});
}
