const std = @import("std");
const mem = std.mem;
const testing = std.testing;

const jsonTypes = @import("./json.types.zig");
const JSONType = jsonTypes.JSONType;
const JSONParsingError = jsonTypes.JSONParsingError;

// https://datatracker.ietf.org/doc/html/rfc8259#section-7
// TODO: accept more scaped characters (U+0000 - U+001F)
// TODO: ignore byte order mark U+FEFF
pub fn parseString(allocator: mem.Allocator, slice: []const u8, index: *u64) JSONParsingError!JSONType {
    var list = std.ArrayList(u8).init(allocator);
    defer list.deinit();
    if (slice[index.*] == '"') {
        index.* += 1;
    }
    var i = index.*;
    while (i < slice.len) {
        var byte = slice[i];
        switch (byte) {
            '"' => {
                break;
            },
            '\\' => {
                i += 1;
                byte = slice[i];
                switch (byte) {
                    '"', '\\', '/' => {
                        try list.append(byte);
                    },
                    'b' => {
                        try list.append(0x08);
                    },
                    't' => {
                        try list.append(0x09);
                    },
                    'n' => {
                        try list.append(0x0A);
                    },
                    'f' => {
                        try list.append(0x0C);
                    },
                    'r' => {
                        try list.append(0x0D);
                    },
                    'u' => {
                        if (i + 4 >= slice.len) {
                            return JSONParsingError.InvalidStringValue;
                        }
                        i += 1;
                        const subSlice = slice[i .. i + 4];
                        const unicodeValue = try parseUnicode(subSlice);
                        try list.appendSlice(&unicodeValue);
                        i += 3;
                    },
                    else => {
                        try list.append(byte);
                    },
                }
            },
            else => {
                try list.append(byte);
            },
        }
        i += 1;
        if (i >= slice.len) {
            return JSONParsingError.InvalidStringValue;
        }
    }

    const strValue = try list.toOwnedSlice();
    index.* = i + 1;
    return JSONType{ .string = strValue };
}

fn parseUnicode(slice: []const u8) JSONParsingError![2]u8 {
    var result: [4]u8 = .{ 0, 0, 0, 0 };
    for (slice, 0..) |value, i| {
        if (value >= '0' and value <= '9') {
            result[i] = (value - '0');
        } else if (value >= 'A' and value <= 'F') {
            result[i] = (10 + (value - 'A'));
        } else if (value >= 'a' and value <= 'f') {
            result[i] = (10 + (value - 'a'));
        } else {
            return JSONParsingError.InvalidUnicodeValue;
        }
    }

    return .{ (result[0] * 16) + result[1], (result[2] * 16) + result[3] };
}

test "should pass - unicode" {
    const result = try parseUnicode(&(.{ 'F', 'f', 'F', 'f' }));
    try testing.expectEqual(255, result[0]);
    try testing.expectEqual(255, result[1]);
}

test "should pass" {
    const slice =
        \\"test"
    ;
    var index: u64 = 0;
    const result = try parseString(testing.allocator, slice, &index);
    defer testing.allocator.free(result.string);
    try testing.expectEqualSlices(u8, "test", result.string);
    try testing.expectEqual(4, result.string.len);
    try testing.expectEqual(6, index);
}

test "should pass - unicode character" {
    const slice =
        \\"test\uf09f\u92a9"
    ;
    var index: u64 = 0;
    const result = try parseString(testing.allocator, slice, &index);
    defer testing.allocator.free(result.string);
    try testing.expectEqualSlices(u8, "test\u{1f4a9}", result.string);
    try testing.expectEqual(8, result.string.len);
    try testing.expectEqual(18, index);
}

test "should pass - empty string" {
    const slice =
        \\""
    ;
    var index: u64 = 0;
    const result = try parseString(testing.allocator, slice, &index);
    defer testing.allocator.free(result.string);
    try testing.expectEqualSlices(u8, "", result.string);
    try testing.expectEqual(0, result.string.len);
    try testing.expectEqual(2, index);
}

test "should pass - escaped characters" {
    const slice =
        \\"\"\\\/\b\f\n\r\t"
    ;
    var index: u64 = 0;
    const result = try parseString(testing.allocator, slice, &index);
    defer testing.allocator.free(result.string);
    const arr = [_]u8{ 0x22, 0x5C, 0x2F, 0x08, 0x0C, 0x0A, 0x0D, 0x09 };
    try testing.expectEqualSlices(u8, &arr, result.string);
    try testing.expectEqual(8, result.string.len);
    try testing.expectEqual(18, index);
}

test "should break - missing end quoatation mark" {
    const slice =
        \\"abc
    ;
    var index: u64 = 0;
    const result = parseString(testing.allocator, slice, &index);
    try testing.expectError(JSONParsingError.InvalidStringValue, result);
}
