const std = @import("std");
const mem = std.mem;
const testing = std.testing;

const jsonTypes = @import("./json.types.zig");
const JSONParsingError = jsonTypes.JSONParsingError;
const JSONType = jsonTypes.JSONType;

const isWhiteSpace = @import("./json.whitespace.zig").isWhiteSpace;
const parseSliceRecursively = @import("./json.zig").parseSliceRecursively;
const parseString = @import("./json.string.zig").parseString;
const parseWhiteSpaces = @import("./json.whitespace.zig").parseWhiteSpaces;

pub fn parseObject(allocator: mem.Allocator, slice: []const u8, index: *u64) JSONParsingError!JSONType {
    var object = std.StringHashMap(JSONType).init(allocator);
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
                try object.put(key.string, value);

                isParsingKey = false;
            },
            else => {
                if (!isParsingKey) {
                    return JSONParsingError.InvalidMapValue;
                }

                value = try parseSliceRecursively(allocator, slice, index);
                try object.put(key.string, value);

                isParsingKey = false;
            },
        }
    }

    return JSONType{ .object = object };
}

test "object - should pass - empty object" {
    const slice = "{}";
    var index: u64 = 0;
    var result = try parseObject(
        testing.allocator,
        slice,
        &index,
    );
    defer result.object.clearAndFree();
    try testing.expectEqual(0, result.object.keyIterator().len);
    try testing.expectEqual(0, result.object.valueIterator().len);
}

test "object - should pass - object string-string" {
    var arenaAllocator = std.heap.ArenaAllocator.init(testing.allocator);
    const alloc = arenaAllocator.allocator();
    defer arenaAllocator.deinit();

    const slice =
        \\{"a":"1"}
    ;
    var index: u64 = 0;
    var result = try parseObject(
        alloc,
        slice,
        &index,
    );

    try testing.expectEqual(1, result.object.count());

    const valueForA = result.object.get("a") orelse unreachable;
    try testing.expectEqualSlices(u8, "1", valueForA.string);
}

test "object - should pass - object string-number" {
    var arenaAllocator = std.heap.ArenaAllocator.init(testing.allocator);
    const alloc = arenaAllocator.allocator();
    defer arenaAllocator.deinit();

    const slice =
        \\{"a":1}
    ;
    var index: u64 = 0;
    var result = try parseObject(
        alloc,
        slice,
        &index,
    );

    try testing.expectEqual(1, result.object.count());

    const valueForA = result.object.get("a") orelse unreachable;
    try testing.expectEqual(1, valueForA.int);
}

test "object - should pass - object string-object" {
    var arenaAllocator = std.heap.ArenaAllocator.init(testing.allocator);
    const alloc = arenaAllocator.allocator();
    defer arenaAllocator.deinit();

    const slice =
        \\{"a":{}}
    ;
    var index: u64 = 0;
    var result = try parseObject(
        alloc,
        slice,
        &index,
    );

    try testing.expectEqual(1, result.object.count());

    const valueForA = result.object.get("a") orelse unreachable;
    try testing.expectEqual(0, valueForA.object.count());
}
