const std = @import("std");
const json = @import("json.zig");
const net = std.net;
const os = std.os;
const process = std.process;
const print = std.debug.print;
const assert = std.debug.assert;

pub fn main() !void {
    var gpa_alloc = std.heap.GeneralPurposeAllocator(.{ .verbose_log = true }){};
    defer assert(gpa_alloc.deinit() == .ok);
    const gpa = gpa_alloc.allocator();

    const file_name = "example-01.json";

    const dir = std.fs.cwd();
    var file = try dir.openFile(file_name, .{ .mode = std.fs.File.OpenMode.read_only });

    defer file.close();

    const file_reader = file.reader().any();

    try json.parseFileReader(gpa, file_reader);
}
