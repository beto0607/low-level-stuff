const std = @import("std");
const mem = std.mem;
const testing = std.testing;

const jsonTypes = @import("./json.types.zig");
const isWhiteSpace = @import("./json.whitespace.zig").isWhiteSpace;
const JSONType = jsonTypes.JSONType;
const JSONParsingError = jsonTypes.JSONParsingError;

pub fn parseNumber(slice: []const u8, index: *u64) !JSONType {
    var isNegative = false;
    var isNegativeExponent = false;
    var isFloat = false;
    var isExponential = false;
    var intPart: i128 = 0;
    var fractionPart: i128 = 0;
    var fractionSize: u64 = 0;
    var exponentPart: i128 = 0;
    var startsWithZero = slice[index.*] == '0';
    var isParsingNumbers = false;

    if (slice[index.*] == '-') {
        isNegative = true;
        index.* += 1;
        startsWithZero = slice[index.*] == '0';
    }

    if (startsWithZero) { // we know first char is '0'
        isParsingNumbers = true;
        index.* += 1;
    }
    while (index.* < slice.len) {
        const byte = slice[index.*];
        index.* += 1;
        switch (byte) {
            '0'...'9' => {
                isParsingNumbers = true;
                if (isExponential) {
                    exponentPart = (exponentPart * 10) + (byte - '0');
                } else if (isFloat) {
                    fractionSize += 1;
                    fractionPart = (fractionPart * 10) + (byte - '0');
                } else {
                    if (startsWithZero) {
                        return JSONParsingError.InvalidNumberValue;
                    }
                    intPart = (intPart * 10) + (byte - '0');
                }
            },
            '.' => {
                if (isExponential or isFloat) {
                    return JSONParsingError.InvalidNumberValue;
                }
                isFloat = true;
            },
            '-' => {
                if (!isExponential or isNegativeExponent or isParsingNumbers) {
                    return JSONParsingError.InvalidNumberValue;
                }
                isNegativeExponent = true;
            },
            '+' => {
                if (!isExponential or isParsingNumbers) {
                    return JSONParsingError.InvalidNumberValue;
                }
                isNegativeExponent = false;
            },
            'e', 'E' => {
                if (isExponential) {
                    return JSONParsingError.InvalidNumberValue;
                }
                isParsingNumbers = false;
                isExponential = true;
            },
            ']', '}', ',' => {
                break;
            },
            else => {
                if (isWhiteSpace(byte)) {
                    break;
                }
                return JSONParsingError.InvalidNumberValue;
            },
        }
        if (index.* >= slice.len) {
            break;
        }
    }

    if (!isParsingNumbers) {
        return JSONParsingError.InvalidNumberValue;
    }

    if (isNegative) {
        intPart *= -1;
    }
    if (isFloat or isExponential) {
        const floatIntPart: f64 = @floatFromInt(intPart);
        var floatFractionPart: f64 = @floatFromInt(fractionPart);
        floatFractionPart = floatFractionPart / std.math.pow(f64, 10, @floatFromInt(fractionSize));
        if (isNegative) {
            floatFractionPart *= -1;
        }
        const floatResult: f64 = floatIntPart + floatFractionPart;

        if (isExponential) {
            if (isNegativeExponent) {
                exponentPart *= -1;
            }
            const exponent: f64 = std.math.pow(f64, 10, @floatFromInt(exponentPart));
            return JSONType{ .float = floatResult * exponent };
        }
        return JSONType{ .float = floatResult };
    } else {
        return JSONType{ .int = intPart };
    }
}

test "should pass - zero" {
    const slice = "0";
    var index: u64 = 0;
    const result = try parseNumber(slice, &index);
    try testing.expectEqual(0, result.int);
    try testing.expectEqual(1, index);
}
test "should pass - int" {
    const slice = "12345";
    var index: u64 = 0;
    const result = try parseNumber(slice, &index);
    try testing.expectEqual(12345, result.int);
    try testing.expectEqual(5, index);
}

test "should pass - neg int" {
    const slice = "-12345";
    var index: u64 = 0;
    const result = try parseNumber(slice, &index);
    try testing.expectEqual(-12345, result.int);
    try testing.expectEqual(6, index);
}

test "should pass - float" {
    const slice = "12.345";
    var index: u64 = 0;
    const result = try parseNumber(slice, &index);
    try testing.expectEqual(12.345, result.float);
    try testing.expectEqual(6, index);
}

test "should pass - float - neg" {
    const slice = "-12.345";
    var index: u64 = 0;
    const result = try parseNumber(slice, &index);
    try testing.expectEqual(-12.345, result.float);
    try testing.expectEqual(7, index);
}

test "should pass - starting with zero" {
    const slice = "0.345";
    var index: u64 = 0;
    const result = try parseNumber(slice, &index);
    try testing.expectEqual(0.345, result.float);
    try testing.expectEqual(5, index);
}

test "should pass - starting with zero - neg" {
    const slice = "-0.345";
    var index: u64 = 0;
    const result = try parseNumber(slice, &index);
    try testing.expectEqual(-0.345, result.float);
    try testing.expectEqual(6, index);
}

test "should pass - exponential" {
    const slice = "1e3";
    var index: u64 = 0;
    const result = try parseNumber(slice, &index);
    try testing.expectEqual(1000, result.float);
    try testing.expectEqual(3, index);
}

test "should pass - exponential - neg" {
    const slice = "-1e3";
    var index: u64 = 0;
    const result = try parseNumber(slice, &index);
    try testing.expectEqual(-1000, result.float);
    try testing.expectEqual(4, index);
}

test "should pass - exponential - neg exp" {
    const slice = "1e-3";
    var index: u64 = 0;
    const result = try parseNumber(slice, &index);
    try testing.expectEqual(0.001, result.float);
    try testing.expectEqual(4, index);
}

test "should pass - exponential - neg exp - neg" {
    const slice = "-1e-3";
    var index: u64 = 0;
    const result = try parseNumber(slice, &index);
    try testing.expectEqual(-0.001, result.float);
    try testing.expectEqual(5, index);
}

test "should pass - exponential+float - neg exp - neg" {
    const slice = "-1.2e-3";
    var index: u64 = 0;
    const result = try parseNumber(slice, &index);
    try testing.expectEqual(-0.0012, result.float);
    try testing.expectEqual(7, index);
}

test "should break - int starting with 0" {
    const slice = "01234";
    var index: u64 = 0;
    const result = parseNumber(slice, &index);
    try testing.expectError(JSONParsingError.InvalidNumberValue, result);
}

test "should break - int starting with 0 - neg" {
    const slice = "-01234";
    var index: u64 = 0;
    const result = parseNumber(slice, &index);
    try testing.expectError(JSONParsingError.InvalidNumberValue, result);
}

test "should break - multiple neg symb" {
    const slice = "--1";
    var index: u64 = 0;
    const result = parseNumber(slice, &index);
    try testing.expectError(JSONParsingError.InvalidNumberValue, result);
}

test "should break - multiple neg symb - exponential" {
    const slice = "1.2e--1";
    var index: u64 = 0;
    const result = parseNumber(slice, &index);
    try testing.expectError(JSONParsingError.InvalidNumberValue, result);
}
test "should break - multiple e symb" {
    const slice = "1.2ee1";
    var index: u64 = 0;
    const result = parseNumber(slice, &index);
    try testing.expectError(JSONParsingError.InvalidNumberValue, result);
}

test "should break - multiple dot symb" {
    const slice = "1.2.3";
    var index: u64 = 0;
    const result = parseNumber(slice, &index);
    try testing.expectError(JSONParsingError.InvalidNumberValue, result);
}

test "should break - + symb after numbers" {
    const slice = "1+1";
    var index: u64 = 0;
    const result = parseNumber(slice, &index);
    try testing.expectError(JSONParsingError.InvalidNumberValue, result);
}
test "should break - - symb after numbers" {
    const slice = "1-1";
    var index: u64 = 0;
    const result = parseNumber(slice, &index);
    try testing.expectError(JSONParsingError.InvalidNumberValue, result);
}

test "should break - + symb after numbers - exponential" {
    const slice = "1e1+1";
    var index: u64 = 0;
    const result = parseNumber(slice, &index);
    try testing.expectError(JSONParsingError.InvalidNumberValue, result);
}

test "should break - +/- symb after numbers - exponential" {
    const slice = "1e1-1";
    var index: u64 = 0;
    const result = parseNumber(slice, &index);
    try testing.expectError(JSONParsingError.InvalidNumberValue, result);
}
