const std = @import("std");
const core = @import("openphone_core.zig");

pub const abi_version: u32 = 1;
const maximum_request_bytes = core.maximum_request_bytes;

const Request = extern struct {
    version: u32,
    bytes: ?[*]const u8,
    bytes_len: usize,
    cancellation_token: u64,
};

comptime {
    std.debug.assert(@sizeOf(Request) >= 24);
}

/// Validates immutable caller-owned bytes without retaining their pointer.
pub export fn openphone_zig_abi_validate_request(request: ?*const Request) c_int {
    const value = request orelse return -1;
    if (value.version != abi_version or value.bytes_len > maximum_request_bytes) return -2;
    if (value.bytes_len != 0 and value.bytes == null) return -3;
    return 0;
}

pub export fn openphone_zig_abi_version() u32 {
    return abi_version;
}
