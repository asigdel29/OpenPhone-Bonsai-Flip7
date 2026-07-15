const std = @import("std");

const product_models = "/product/etc/bonsai/models/";
pub const Decision = enum { allow, busy, deny_asset };

/// Admits only read-only product-partition assets and a single active generation.
pub fn admit(asset_path: []const u8, active_generation: bool) Decision {
    if (!std.mem.startsWith(u8, asset_path, product_models) or
        std.mem.indexOf(u8, asset_path, "..") != null) return .deny_asset;
    return if (active_generation) .busy else .allow;
}

test "Bonsai admission is local and single-flight" {
    try std.testing.expectEqual(Decision.allow, admit("/product/etc/bonsai/models/model.gguf", false));
    try std.testing.expectEqual(Decision.busy, admit("/product/etc/bonsai/models/model.gguf", true));
    try std.testing.expectEqual(Decision.deny_asset, admit("/data/local/tmp/model.gguf", false));
}
