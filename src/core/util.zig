const platform = @import("platform");
const t = @import("types");

/// Deallocates the state in a defined manner
pub fn dealloc_state(state: t.StateInterface) void {
    var slice: []u8 = undefined;
    slice.ptr = @ptrCast(@alignCast(state.ptr));
    slice.len = state.size;

    const allocator_inst = platform.Allocator.allocator() catch return;
    allocator_inst.free(slice);
}

// Public utility for allocatiing state
pub export fn aether_allocate_state(size: usize) ?[*]u8 {
    const alloc = platform.Allocator.allocator() catch return null;
    const res = alloc.alloc(u8, size) catch return null;
    return res.ptr;
}
