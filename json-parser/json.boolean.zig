const std = @import("std");
const mem = std.mem;
const testing = std.testing;

const jsonTypes = @import("./json.types.zig");
const JSONType = jsonTypes.JSONType;
const JSONParsingError = jsonTypes.JSONParsingError;

pub fn parseBoolean(slice: []const u8, index: *u64) JSONParsingError!JSONType {
    if (slice.len < index.* + 4) {
        return JSONParsingError.InvalidBooleanValue;
    }
    if (mem.eql(u8, slice[index.* .. index.* + 4], "true")) {
        index.* += 4;
        return JSONType{ .boolean = true };
    } else if (slice.len >= index.* + 5 and
        mem.eql(u8, slice[index.* .. index.* + 5], "false"))
    {
        index.* += 5;
        return JSONType{ .boolean = false };
    } else {
        return JSONParsingError.InvalidBooleanValue;
    }
}

test "should pass - true" {
    const slice = "    true";
    var index: u64 = 4;
    const result = try parseBoolean(slice, &index);
    try testing.expectEqual(true, result.boolean);
    try testing.expectEqual(index, 8);
}

test "should pass - false" {
    const slice = "    false";
    var index: u64 = 4;
    const result = try parseBoolean(slice, &index);
    try testing.expectEqual(false, result.boolean);
    try testing.expectEqual(index, 9);
}

test "should break - too short" {
    const slice = "";
    var index: u64 = 0;
    const result = parseBoolean(slice, &index);
    try testing.expectError(JSONParsingError.InvalidBooleanValue, result);
}

test "should break - invalid chars" {
    const slice = "abcd";
    var index: u64 = 0;
    const result = parseBoolean(slice, &index);
    try testing.expectError(JSONParsingError.InvalidBooleanValue, result);
}

test "should break - case sensitive - TRUE" {
    const slice = "TRUE";
    var index: u64 = 0;
    const result = parseBoolean(slice, &index);
    try testing.expectError(JSONParsingError.InvalidBooleanValue, result);
}

test "should break - case sensitive - FALSE" {
    const slice = "FALSE";
    var index: u64 = 0;
    const result = parseBoolean(slice, &index);
    try testing.expectError(JSONParsingError.InvalidBooleanValue, result);
}
