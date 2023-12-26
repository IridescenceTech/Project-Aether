// Portability Notes: Allocator may not be cross platform

const std = @import("std");
const t = @import("types");

const engine = @import("engine.zig");

var initialized: bool = false;

var gpa: std.heap.GeneralPurposeAllocator(.{}) = undefined;
var allocator_inst: std.mem.Allocator = undefined;

/// Initialize a global allocator
pub fn init() void {
    initialized = true;
    gpa = std.heap.GeneralPurposeAllocator(.{}){};
    allocator_inst = gpa.allocator();
}

/// Gets the global allocator
pub fn allocator() !std.mem.Allocator {
    if (!initialized) {
        return error.UtilNotInitialized;
    }

    return allocator_inst;
}

/// Deallocates the state in a defined manner
pub fn dealloc_state(state: t.StateInterface) void {
    var slice: []u8 = undefined;
    slice.ptr = @ptrCast(@alignCast(state.ptr));
    slice.len = state.size;

    allocator_inst.free(slice);
}

// Public utility for allocatiing state
pub export fn aether_allocate_state(size: usize) ?[*]u8 {
    const alloc = allocator() catch return null;
    const res = alloc.alloc(u8, size) catch return null;
    return res.ptr;
}
