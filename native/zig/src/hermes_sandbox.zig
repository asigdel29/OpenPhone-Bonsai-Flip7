pub const Decision = enum { allow, deny_network, deny_tool };
pub fn authorize(network_enabled: bool, requested_network: bool, tool_allowed: bool) Decision {
    if (requested_network and !network_enabled) return .deny_network;
    return if (tool_allowed) .allow else .deny_tool;
}
test "Hermes has no ambient network or tools" {
    const std = @import("std");
    try std.testing.expectEqual(Decision.deny_network, authorize(false, true, true));
    try std.testing.expectEqual(Decision.deny_tool, authorize(true, false, false));
}
