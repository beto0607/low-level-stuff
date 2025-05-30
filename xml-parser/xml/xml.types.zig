const std = @import("std");
const mem = std.mem;

pub const XMLResult = struct {
    prolog: ?XMLProlog,
    root: XMLElement,
    allocator: mem.Allocator,
};

pub const XMLProlog = struct {
    attributes: []XMLAttribute,
};

pub const XMLElement = struct {
    children: []XMLElement,
    tagName: []const u8,
    attributes: []XMLAttribute,
    parent: ?XMLElement,
    text: ?XMLText,
    namespaces: ?[]XMLNamespace,

    selfClosing: bool,
};

pub const XMLAttribute = struct {
    name: []const u8,
    value: []const u8,
};
pub const XMLNamespace = struct {
    prefix: []const u8,
    uri: []const u8,
};

pub const XMLText = struct {
    value: []const u8,
};

pub const XMLSpecialCharacters = struct {
    LessThan: "&lt;",
    GreaterThan: "&gt;",
    Ampersand: "&amp;",
    Apostrophe: "&apos;",
    QuotationMark: "&quot;",
};

pub const XMLParserErrors = error{
    SyntaxError,
    InvalidNamespace,
};
