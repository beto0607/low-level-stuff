const std = @import("std");
const testing = std.testing;

pub fn parseWhiteSpaces(slice: []const u8, index: *u64) void {
    var byte = slice[index.*];
    while (isWhiteSpace(byte)) {
        index.* += 1;
        if (index.* >= slice.len) {
            break;
        }
        byte = slice[index.*];
    }
}

pub fn isWhiteSpace(byte: u8) bool {
    return (byte == 0x20 or byte == 0x09 or byte == 0x0A or byte == 0x0D);
}

test "isWhiteSpace - ' '" {
    try testing.expect(isWhiteSpace(' '));
}

test "isWhiteSpace - '\t'" {
    try testing.expect(isWhiteSpace('\t'));
}

test "isWhiteSpace - '\n'" {
    try testing.expect(isWhiteSpace('\n'));
}

test "isWhiteSpace - '\r'" {
    try testing.expect(isWhiteSpace('\r'));
}

test "isWhiteSpace - false" {
    try testing.expect(isWhiteSpace('a') == false);
    try testing.expect(isWhiteSpace('9') == false);
}

test "parseWhiteSpaces" {
    const slice = "    ";
    var index: u64 = 0;
    parseWhiteSpaces(slice, &index);
    try testing.expectEqual(slice.len, index);
}

test "parseWhiteSpaces - index > 0" {
    const slice = "ab    ";
    var index: u64 = 2;
    parseWhiteSpaces(slice, &index);
    try testing.expectEqual(slice.len, index);
}

test "parseWhiteSpaces - ends with char" {
    const slice = "    3";
    var index: u64 = 0;
    parseWhiteSpaces(slice, &index);
    try testing.expectEqual(slice.len - 1, index);
}
