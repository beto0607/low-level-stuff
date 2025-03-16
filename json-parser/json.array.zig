const std = @import("std");
const mem = std.mem;
const testing = std.testing;

const parseSliceRecursively = @import("./json.zig").parseSliceRecursively;
const jsonTypes = @import("./json.types.zig");
const isWhiteSpace = @import("./json.whitespace.zig").isWhiteSpace;
const parseWhiteSpaces = @import("./json.whitespace.zig").parseWhiteSpaces;
const JSONType = jsonTypes.JSONType;
const JSONParsingError = jsonTypes.JSONParsingError;

pub fn parseArray(allocator: mem.Allocator, slice: []const u8, index: *u64) JSONParsingError!JSONType {
    var list = std.ArrayList(JSONType).init(allocator);
    defer list.deinit();
    if (slice[index.*] == '[') {
        index.* += 1;
    }
    while (index.* < slice.len) {
        parseWhiteSpaces(slice, index);
        const byte = slice[index.*];
        switch (byte) {
            ']' => {
                break;
            },
            ',' => {
                index.* += 1;
                continue;
            },
            else => {
                try list.append(try parseSliceRecursively(allocator, slice, index));
            },
        }
    }
    return JSONType{ .array = try list.toOwnedSlice() };
}

test "array - should pass - empty array" {
    const slice = "[]";
    var index: u64 = 0;
    const result = try parseArray(
        testing.allocator,
        slice,
        &index,
    );
    defer testing.allocator.free(result.array);
    try testing.expect(result.array.len == 0);
}

test "array - should pass - numbers array" {
    const slice = "[1,2,3]";
    var index: u64 = 0;
    const result = try parseArray(
        testing.allocator,
        slice,
        &index,
    );
    defer testing.allocator.free(result.array);
    try testing.expect(result.array.len == 3);
    try testing.expect(result.array[0].int == 1);
    try testing.expect(result.array[1].int == 2);
    try testing.expect(result.array[2].int == 3);
}

test "array - should pass - string array" {
    var arenaAllocator = std.heap.ArenaAllocator.init(testing.allocator);
    const alloc = arenaAllocator.allocator();
    defer arenaAllocator.deinit();

    const slice =
        \\["1", "22", "333"]
    ;
    var index: u64 = 0;
    const result = try parseArray(alloc, slice, &index);
    try testing.expect(result.array.len == 3);
    try testing.expectEqualSlices(u8, "1", result.array[0].string);
    try testing.expectEqualSlices(u8, "22", result.array[1].string);
    try testing.expectEqualSlices(u8, "333", result.array[2].string);
}

test "array - should pass - mixed array" {
    var arenaAllocator = std.heap.ArenaAllocator.init(testing.allocator);
    const alloc = arenaAllocator.allocator();
    defer arenaAllocator.deinit();

    const slice =
        \\["string", false, true, null, [1]]
    ;
    var index: u64 = 0;
    const result = try parseArray(alloc, slice, &index);
    try testing.expectEqual(5, result.array.len);
    try testing.expectEqualSlices(u8, "string", result.array[0].string);
    try testing.expectEqual(false, result.array[1].boolean);
    try testing.expectEqual(true, result.array[2].boolean);
    try testing.expectEqual(null, result.array[3].null);
    try testing.expectEqual(1, result.array[4].array.len);
    try testing.expectEqual(1, result.array[4].array[0].int);
}
