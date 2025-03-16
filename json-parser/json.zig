const std = @import("std");
const fs = std.fs;
const io = std.io;
const mem = std.mem;
const print = std.debug.print;
const testing = std.testing;

const jsonTypes = @import("./json.types.zig");
const JSONParsingError = jsonTypes.JSONParsingError;
const JSONResult = jsonTypes.JSONResult;
const JSONType = jsonTypes.JSONType;

const parseArray = @import("./json.array.zig").parseArray;
const parseBoolean = @import("./json.boolean.zig").parseBoolean;
const parseNull = @import("./json.null.zig").parseNull;
const parseNumber = @import("./json.number.zig").parseNumber;
const parseObject = @import("./json.object.zig").parseObject;
const parseString = @import("./json.string.zig").parseString;
const parseWhiteSpaces = @import("./json.whitespace.zig").parseWhiteSpaces;

pub fn parseFromSlice(allocator: mem.Allocator, slice: []const u8) JSONParsingError!JSONResult {
    var arenaAllocator = std.heap.ArenaAllocator.init(allocator);
    var alloc = arenaAllocator.allocator();
    var result = try alloc.create(JSONResult);
    result.allocator = arenaAllocator;

    var index: u64 = 0;
    result.value = parseSliceRecursively(allocator, slice, &index);

    return result;
}

pub fn parseSliceRecursively(allocator: mem.Allocator, slice: []const u8, index: *u64) JSONParsingError!JSONType {
    parseWhiteSpaces(slice, index);
    const byte = slice[index.*];
    switch (byte) {
        '{' => {
            return try parseObject(allocator, slice, index);
        },
        '[' => {
            return try parseArray(allocator, slice, index);
        },
        '"' => {
            return try parseString(allocator, slice, index);
        },
        'f', 't' => {
            return try parseBoolean(slice, index);
        },
        '0'...'9', '-' => {
            return try parseNumber(slice, index);
        },
        'n' => {
            return try parseNull(slice, index);
        },
        else => {
            return JSONParsingError.SyntaxErorr;
        },
    }
    unreachable;
}
