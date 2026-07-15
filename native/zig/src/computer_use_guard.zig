const std = @import("std");

pub const Request = struct { has_grant: bool, requires_confirmation: bool, confirmed: bool, idempotency_key: []const u8 };
pub const Decision = enum { allow, deny_grant, deny_confirmation, deny_idempotency };

/// Planning is local; Android remains responsible for grants, confirmation, execution, and audit.
pub fn authorize(request: Request) Decision {
    if (!request.has_grant) return .deny_grant;
    if (request.requires_confirmation and !request.confirmed) return .deny_confirmation;
    if (request.idempotency_key.len == 0 or request.idempotency_key.len > 128) return .deny_idempotency;
    return .allow;
}

test "computer use fails closed before framework execution" {
    try std.testing.expectEqual(Decision.deny_grant, authorize(.{ .has_grant = false, .requires_confirmation = false, .confirmed = false, .idempotency_key = "a" }));
    try std.testing.expectEqual(Decision.deny_confirmation, authorize(.{ .has_grant = true, .requires_confirmation = true, .confirmed = false, .idempotency_key = "a" }));
    try std.testing.expectEqual(Decision.allow, authorize(.{ .has_grant = true, .requires_confirmation = true, .confirmed = true, .idempotency_key = "a" }));
}
