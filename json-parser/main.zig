const std = @import("std");
const net = std.net;
const os = std.os;
const process = std.process;
const print = std.debug.print;
const assert = std.debug.assert;

pub fn main() !void {
    var gpa_alloc = std.heap.GeneralPurposeAllocator(.{ .verbose_log = true }){};
    defer assert(gpa_alloc.deinit() == .ok);
    const gpa = gpa_alloc.allocator();
    _ = gpa; // autofix
}
