const std = @import("std");

pub const maximum_record_bytes = 64 * 1024;
pub const Encoding = enum { legacy_json, zig_v1 };
pub const Record = struct { encoding: Encoding, kind: []const u8, payload: []const u8 };

/// Decodes either the legacy JSON payload or the additive OPZ1 envelope without allocation.
pub fn decode(bytes: []const u8) !Record {
    if (bytes.len > maximum_record_bytes) return error.TooLarge;
    const prefix = "OPZ1\n";
    if (!std.mem.startsWith(u8, bytes, prefix)) return .{ .encoding = .legacy_json, .kind = "legacy_json", .payload = bytes };
    const remainder = bytes[prefix.len..];
    const end = std.mem.indexOfScalar(u8, remainder, '\n') orelse return error.Malformed;
    const kind = remainder[0..end];
    if (kind.len == 0 or kind.len > 32) return error.Malformed;
    return .{ .encoding = .zig_v1, .kind = kind, .payload = remainder[end + 1 ..] };
}

/// Writes the additive envelope; callers retain the legacy record until parity is verified.
pub fn encode(writer: anytype, kind: []const u8, payload: []const u8) !void {
    if (kind.len == 0 or kind.len > 32 or payload.len > maximum_record_bytes) return error.Invalid;
    try writer.writeAll("OPZ1\n");
    try writer.writeAll(kind);
    try writer.writeByte('\n');
    try writer.writeAll(payload);
}

test "dual reads legacy and versioned records" {
    const legacy = try decode("{\"sessions\":[]}");
    try std.testing.expectEqual(Encoding.legacy_json, legacy.encoding);
    const current = try decode("OPZ1\nsessions\n[]");
    try std.testing.expectEqualStrings("sessions", current.kind);
    try std.testing.expectEqualStrings("[]", current.payload);
}
