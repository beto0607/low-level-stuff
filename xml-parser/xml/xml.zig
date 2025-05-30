const std = @import("std");
const fs = std.fs;
const io = std.io;
const mem = std.mem;
const print = std.debug.print;

const XMLTypes = @import("./xml.types.zig");
const XMLParserErrors = XMLTypes.XMLParserErrors;
const XMLSpecialCharacters = XMLTypes.XMLSpecialCharacters;
const XMLResult = XMLTypes.XMLResult;

pub fn parseFromSlice(allocator: mem.Allocator, slice: []const u8) XMLParserErrors!XMLResult {
    _ = slice; // autofix
    var arenaAllocator = std.heap.ArenaAllocator.init(allocator);
    var alloc = arenaAllocator.allocator();
    var result = try alloc.create(XMLResult);
    var index: u64 = 0;
    result.value = parseSliceRecursively(allocator, slice, &index);
    return result;
}
