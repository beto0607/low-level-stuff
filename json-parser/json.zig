const std = @import("std");
const fs = std.fs;
const io = std.io;
const mem = std.mem;
const print = std.debug.print;
const testing = std.testing;

const jsonTypes = @import("./json.types.zig");
const JSONResult = jsonTypes.JSONResult;
const JSONType = jsonTypes.JSONType;
const JSONParsingError = jsonTypes.JSONParsingError;

const parseWhiteSpaces = @import("./json.whitespace.zig").parseWhiteSpaces;
const parseNull = @import("./json.null.zig").parseNull;
const parseArray = @import("./json.array.zig").parseArray;
const parseNumber = @import("./json.number.zig").parseNumber;
const parseBoolean = @import("./json.boolean.zig").parseBoolean;
const parseString = @import("./json.string.zig").parseString;
const parseMap = @import("./json.map.zig").parseMap;

pub fn parseFromSlice(allocator: mem.Allocator, slice: []const u8) !*JSONResult {
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
            return try parseMap(allocator, slice, index);
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

// fn parseMap(allocator: mem.Allocator, slice: []const u8, index: *u64) !JSONType {
//     _ = index; // autofix
//     _ = slice; // autofix
//     _ = allocator; // autofix
//     const result = JSONType{
//         .null = null,
//         // .map = std.AutoHashMap([]const u8, JSONType).init(allocator),
//     };
//     // var i = index;
//     // var byte = slice[i];
//     // while (index < slice.len and byte != '}') {
//     //     byte = slice[i];
//     //     result.map.put(
//     //         "test",
//     //     );
//     //     i += 1;
//     // }
//     return result;
// }

// fn parseArray(allocator: mem.Allocator, slice: []const u8, index: *u64) !JSONType {
//     var list = std.ArrayList(JSONType).init(allocator);
//     defer list.deinit();
//     while (index.* < slice.len) {
//         parseWhiteSpaces(slice, index);
//         const byte = slice[index.*];
//         switch (byte) {
//             ']' => {
//                 break;
//             },
//             else => {
//                 const innerElement = try parseSliceRecursively(allocator, slice, index);
//                 try list.append(innerElement);
//             },
//         }
//     }
//     return JSONType{ .array = try list.toOwnedSlice() };
// }
//
// test "should pass - empty array" {
//     const slice = "[]";
//     var index: u64 = 0;
//     const result = try parseArray(
//         testing.allocator,
//         slice,
//         &index,
//     );
//     try testing.expect(result.array.len == 0);
// }
