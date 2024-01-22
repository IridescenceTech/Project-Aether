const std = @import("std");
const platform = @import("platform");
const t = @import("../types.zig");

pub fn allocator() std.mem.Allocator {
    return platform.Allocator.allocator() catch unreachable;
}

/// Deallocates the state in a defined manner
pub fn dealloc_state(state: t.StateInterface) void {
    var slice: []u8 = undefined;
    slice.ptr = @ptrCast(@alignCast(state.ptr));
    slice.len = state.size;

    const allocator_inst = platform.Allocator.allocator() catch return;
    allocator_inst.free(slice);
}

/// Allocates the state in a defined manner
pub fn alloc_state(comptime T: type) !*T {
    const allocator_inst = platform.Allocator.allocator() catch return error.DeallocatorNotFound;

    const slice = try allocator_inst.alloc(u8, @sizeOf(T));
    const ptr = @as(*T, @ptrCast(@alignCast(slice.ptr)));
    ptr.* = T{};

    return ptr;
}
