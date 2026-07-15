const std = @import("std");

pub const maximum_request_bytes = 64 * 1024;
pub const Core = opaque {};
const State = struct {
    allocator: std.mem.Allocator,
    lock: std.Thread.Mutex = .{},
    result: []u8 = &.{},
    active: bool = false,
    cancelled_token: u64 = 0,
};

pub const Request = extern struct {
    bytes: ?[*]const u8,
    bytes_len: usize,
    cancellation_token: u64,
};

fn state(handle: *Core) *State {
    return @ptrCast(@alignCast(handle));
}

/// Creates a handle that owns its page-allocator allocation until destroy.
pub export fn openphone_zig_core_create() ?*Core {
    const value = std.heap.page_allocator.create(State) catch return null;
    value.* = .{ .allocator = std.heap.page_allocator };
    return @ptrCast(value);
}

/// Cancels the matching request. It never waits for generation to complete.
pub export fn openphone_zig_core_cancel(handle: ?*Core, token: u64) c_int {
    const value = state(handle orelse return -1);
    value.lock.lock();
    value.cancelled_token = token;
    value.lock.unlock();
    return 0;
}

/// Copies bounded immutable caller bytes and never retains their pointer.
pub export fn openphone_zig_core_generate(handle: ?*Core, request: ?*const Request) c_int {
    const value = state(handle orelse return -1);
    const input = request orelse return -2;
    if (input.bytes_len > maximum_request_bytes or (input.bytes_len != 0 and input.bytes == null)) return -3;
    value.lock.lock();
    if (value.active) {
        value.lock.unlock();
        return -4;
    }
    value.active = true;
    const cancelled = value.cancelled_token == input.cancellation_token;
    value.lock.unlock();
    defer {
        value.lock.lock();
        value.active = false;
        value.lock.unlock();
    }
    if (cancelled) return -5;
    const bytes: []const u8 = if (input.bytes) |pointer|
        pointer[0..input.bytes_len]
    else
        &.{};
    const copy = value.allocator.dupe(u8, bytes) catch return -6;
    value.lock.lock();
    if (value.cancelled_token == input.cancellation_token) {
        value.lock.unlock();
        value.allocator.free(copy);
        return -5;
    }
    value.allocator.free(value.result);
    value.result = copy;
    value.lock.unlock();
    return 0;
}

/// Copies the core-owned immutable result into a caller-owned output buffer.
pub export fn openphone_zig_core_copy_result(handle: ?*Core, output: ?[*]u8, capacity: usize) isize {
    const value = state(handle orelse return -1);
    value.lock.lock();
    defer value.lock.unlock();
    if (capacity < value.result.len) return -2;
    if (value.result.len != 0) {
        const destination = output orelse return -2;
        @memcpy(destination[0..value.result.len], value.result);
    }
    return @intCast(value.result.len);
}

pub export fn openphone_zig_core_destroy(handle: ?*Core) void {
    const value = state(handle orelse return);
    value.lock.lock();
    const result = value.result;
    value.result = &.{};
    value.lock.unlock();
    value.allocator.free(result);
    value.allocator.destroy(value);
}
