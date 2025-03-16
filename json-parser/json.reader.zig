const std = @import("std");
const mem = std.mem;
const fs = std.fs;
const io = std.io;
const print = std.debug.print;

const isWhiteSpace = @import("./json.whitespace.zig").isWhiteSpace;

const JSONResult = @import("./json.types.zig").JSONResult;

pub fn parseFromReader(allocator: mem.Allocator, stream: io.AnyReader) !JSONResult {
    const arenaAllocator = std.heap.ArenaAllocator.init(allocator);
    var result = JSONResult(.{ .allocator = arenaAllocator, .value = .{} });
    defer result = undefined;

    outer: while (true) {
        var byte = stream.readByte() catch break;
        while (isWhiteSpace(byte)) {
            print("'{any}' was isWhiteSpace\n", .{byte});
            byte = stream.readByte() catch break :outer;
        }
    }
    return result;
}
