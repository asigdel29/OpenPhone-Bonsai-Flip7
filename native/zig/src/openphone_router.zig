const std = @import("std");

pub const maximum_tool_name_bytes = 96;
pub const Decision = enum { allow, deny_unknown, deny_malformed };

/// Resolves only exact registered tool names; Android still performs execution and auditing.
pub fn resolve(tool_name: []const u8, registered: []const []const u8) Decision {
    if (tool_name.len == 0 or tool_name.len > maximum_tool_name_bytes) return .deny_malformed;
    for (registered) |candidate| if (std.mem.eql(u8, tool_name, candidate)) return .allow;
    return .deny_unknown;
}

test "routing fails closed" {
    const tools = [_][]const u8{ "openphone.screen.get", "openphone.action.request" };
    try std.testing.expectEqual(Decision.allow, resolve("openphone.screen.get", &tools));
    try std.testing.expectEqual(Decision.deny_unknown, resolve("openphone.shell", &tools));
    try std.testing.expectEqual(Decision.deny_malformed, resolve("", &tools));
}
