const std = @import("std");
const print = std.debug.print;
const assert = std.debug.assert;

pub fn main() !void {
    var gpa_alloc = std.heap.GeneralPurposeAllocator(.{}){};
    defer assert(gpa_alloc.deinit() == .ok);
    const gpa = gpa_alloc.allocator();
    _ = gpa; // autofix
}
