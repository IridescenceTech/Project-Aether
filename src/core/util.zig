const platform = @import("platform");
const t = @import("../types.zig");

/// Deallocates the state in a defined manner
pub fn dealloc_state(state: t.StateInterface) void {
    var slice: []u8 = undefined;
    slice.ptr = @ptrCast(@alignCast(state.ptr));
    slice.len = state.size;

    const allocator_inst = platform.Allocator.allocator() catch return;
    allocator_inst.free(slice);
}
