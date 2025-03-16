const std = @import("std");
const mem = std.mem;
const testing = std.testing;

const jsonTypes = @import("./json.types.zig");
const JSONParsingError = jsonTypes.JSONParsingError;
const JSONType = jsonTypes.JSONType;

pub fn parseNull(slice: []const u8, index: *u64) JSONParsingError!JSONType {
    if (slice.len < index.* + 3) {
        return JSONParsingError.InvalidNullValue;
    }
    if (mem.eql(u8, slice[index.* .. index.* + 4], "null")) {
        index.* += 4;
        return JSONType{ .null = null };
    }
    return JSONParsingError.InvalidNullValue;
}

test "should pass" {
    const slice = "    null";
    var index: u64 = 4;
    const result = try parseNull(slice, &index);
    try testing.expectEqual(null, result.null);
    try testing.expectEqual(index, 8);
}

test "should break - too short" {
    const slice = "";
    var index: u64 = 0;
    const result = parseNull(slice, &index);
    try testing.expectError(JSONParsingError.InvalidNullValue, result);
}

test "should break - invalid chars" {
    const slice = "abcd";
    var index: u64 = 0;
    const result = parseNull(slice, &index);
    try testing.expectError(JSONParsingError.InvalidNullValue, result);
}

test "should break - case sensitive" {
    const slice = "NULL";
    var index: u64 = 0;
    const result = parseNull(slice, &index);
    try testing.expectError(JSONParsingError.InvalidNullValue, result);
}
