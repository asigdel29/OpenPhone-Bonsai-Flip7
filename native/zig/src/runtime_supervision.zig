pub const State = enum { stopped, running, backoff };
pub fn transition(state: State, crashed: bool, cancelled: bool) State {
    if (cancelled) return .stopped;
    if (crashed) return .backoff;
    return state;
}
test "supervision backs off crashes and honors cancellation" {
    const std = @import("std");
    try std.testing.expectEqual(State.backoff, transition(.running, true, false));
    try std.testing.expectEqual(State.stopped, transition(.running, true, true));
}
