const std = @import("std");
const mem = std.mem;
const testing = std.testing;

const parseSliceRecursively = @import("./json.zig").parseSliceRecursively;
const jsonTypes = @import("./json.types.zig");
const isWhiteSpace = @import("./json.whitespace.zig").isWhiteSpace;
const parseWhiteSpaces = @import("./json.whitespace.zig").parseWhiteSpaces;
const parseString = @import("./json.string.zig").parseString;
const JSONType = jsonTypes.JSONType;
const JSONParsingError = jsonTypes.JSONParsingError;

pub fn parseMap(allocator: mem.Allocator, slice: []const u8, index: *u64) JSONParsingError!JSONType {
    var map = std.StringHashMap(JSONType).init(allocator);
    if (slice[index.*] == '{') {
        index.* += 1;
    } else {
        return JSONParsingError.InvalidMapValue;
    }

    var isParsingKey = false;
    var key: JSONType = undefined;
    var value: JSONType = undefined;
    while (index.* < slice.len) {
        parseWhiteSpaces(slice, index);
        const byte = slice[index.*];
        switch (byte) {
            '}' => {
                if (isParsingKey) {
                    return JSONParsingError.InvalidMapValue;
                }
                break;
            },
            ',' => {
                if (isParsingKey) {
                    return JSONParsingError.InvalidMapValue;
                }
                index.* += 1;
                continue;
            },
            ':' => {
                index.* += 1;
                continue;
            },
            '"' => {
                if (!isParsingKey) {
                    key = try parseString(allocator, slice, index);
                    isParsingKey = true;
                    continue;
                }

                value = try parseSliceRecursively(allocator, slice, index);
                try map.put(key.string, value);

                isParsingKey = false;
            },
            else => {
                if (!isParsingKey) {
                    return JSONParsingError.InvalidMapValue;
                }

                value = try parseSliceRecursively(allocator, slice, index);
                try map.put(key.string, value);

                isParsingKey = false;
            },
        }
    }

    return JSONType{ .map = map };
}

test "map - should pass - empty map" {
    const slice = "{}";
    var index: u64 = 0;
    var result = try parseMap(
        testing.allocator,
        slice,
        &index,
    );
    defer result.map.clearAndFree();
    try testing.expectEqual(0, result.map.keyIterator().len);
    try testing.expectEqual(0, result.map.valueIterator().len);
}

test "map - should pass - map string-string" {
    var arenaAllocator = std.heap.ArenaAllocator.init(testing.allocator);
    const alloc = arenaAllocator.allocator();
    defer arenaAllocator.deinit();

    const slice =
        \\{"a":"1"}
    ;
    var index: u64 = 0;
    var result = try parseMap(
        alloc,
        slice,
        &index,
    );

    try testing.expectEqual(1, result.map.count());

    const valueForA = result.map.get("a") orelse unreachable;
    try testing.expectEqualSlices(u8, "1", valueForA.string);
}

test "map - should pass - map string-number" {
    var arenaAllocator = std.heap.ArenaAllocator.init(testing.allocator);
    const alloc = arenaAllocator.allocator();
    defer arenaAllocator.deinit();

    const slice =
        \\{"a":1}
    ;
    var index: u64 = 0;
    var result = try parseMap(
        alloc,
        slice,
        &index,
    );

    try testing.expectEqual(1, result.map.count());

    const valueForA = result.map.get("a") orelse unreachable;
    try testing.expectEqual(1, valueForA.int);
}

test "map - should pass - map string-map" {
    var arenaAllocator = std.heap.ArenaAllocator.init(testing.allocator);
    const alloc = arenaAllocator.allocator();
    defer arenaAllocator.deinit();

    const slice =
        \\{"a":{}}
    ;
    var index: u64 = 0;
    var result = try parseMap(
        alloc,
        slice,
        &index,
    );

    try testing.expectEqual(1, result.map.count());

    const valueForA = result.map.get("a") orelse unreachable;
    try testing.expectEqual(0, valueForA.map.count());
}
