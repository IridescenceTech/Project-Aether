pub const Types = @import("types.zig");

pub extern fn aether_get_app_interface() Types.AppInterface;
pub extern fn aether_allocate(size: usize) ?[*]u8;

pub const Util = struct {
    pub fn allocate(comptime T: type) !*T {
        var data = aether_allocate(@sizeOf(T));
        if (data) |d| {
            var t = @as(*T, @ptrCast(@alignCast(d)));
            t.* = T{};
            return t;
        } else {
            return error.AllocationFailure;
        }
    }
};
