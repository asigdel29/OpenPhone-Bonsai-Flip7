pub const Decision = enum { local, remote, deny };
pub fn select(enabled: bool, disclosed: bool, request_bytes: usize) Decision {
    if (!enabled) return .local;
    if (!disclosed or request_bytes > 64 * 1024) return .deny;
    return .remote;
}
test "remote fallback is opt-in and bounded" {
    const std = @import("std");
    try std.testing.expectEqual(Decision.local, select(false, false, 1));
    try std.testing.expectEqual(Decision.deny, select(true, false, 1));
    try std.testing.expectEqual(Decision.remote, select(true, true, 1));
}
