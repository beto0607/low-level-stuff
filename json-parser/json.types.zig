const std = @import("std");
const mem = std.mem;

pub const JSONResult = struct {
    value: JSONType,
    allocator: std.heap.ArenaAllocator,
};

pub const JSONType = union {
    int: i128,
    float: f64,
    string: []const u8,
    boolean: bool,
    object: std.StringHashMap(JSONType),
    array: []JSONType,
    null: ?u1,
};

pub const JSONParsingError = mem.Allocator.Error || error{
    SyntaxError,
    InvalidArrayValue,
    InvalidBooleanValue,
    InvalidObjectValue,
    InvalidNullValue,
    InvalidNumberValue,
    InvalidStringValue,
    InvalidUnicodeValue,
};
