pub const Transport = enum { local, openrouter };
pub fn select(local_ready: bool, remote_allowed: bool) ?Transport {
    if (local_ready) return .local;
    if (remote_allowed) return .openrouter;
    return null;
}
test "broker keeps local preference" {
    const std = @import("std");
    try std.testing.expectEqual(Transport.local, select(true, true).?);
    try std.testing.expect(select(false, false) == null);
}
