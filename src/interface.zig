const std = @import("std");

pub const Types = @import("types.zig");

pub extern fn aether_get_app_interface() Types.AppInterface;
pub extern fn aether_allocate_state(size: usize) ?[*]u8;
pub extern fn aether_log(str: [*]const u8, size: usize) void;

pub const Util = struct {
    pub fn allocate_state(comptime T: type) !*T {
        var data = aether_allocate_state(@sizeOf(T));
        if (data) |d| {
            var t = @as(*T, @ptrCast(@alignCast(d)));
            t.* = T{};
            return t;
        } else {
            return error.AllocationFailure;
        }
    }

    pub fn log(comptime format: []const u8, args: anytype) void {
        var buf: [1024]u8 = [_]u8{0} ** 1024;
        var slice = std.fmt.bufPrint(&buf, format, args) catch return;

        aether_log(slice.ptr, slice.len);
    }
};
