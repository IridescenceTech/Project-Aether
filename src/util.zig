const std = @import("std");
const engine = @import("engine.zig");
const t = @import("types.zig");

pub const std_options = struct {
    pub const log_level = .debug;
    pub const logFn = log;
};

var initialized: bool = false;

var gpa: std.heap.GeneralPurposeAllocator(.{}) = undefined;
var allocator_inst: std.mem.Allocator = undefined;

pub fn init() void {
    initialized = true;
    gpa = std.heap.GeneralPurposeAllocator(.{}){};
    allocator_inst = gpa.allocator();
}

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

/// Custom logger function
pub fn log(comptime level: std.log.Level, comptime scope: @TypeOf(.EnumLiteral), comptime format: []const u8, args: anytype) void {
    _ = scope;

    const prefix = "[" ++ comptime level.asText() ++ "]: ";

    const mutex = std.debug.getStderrMutex();
    mutex.lock();
    defer std.debug.getStderrMutex().unlock();

    const stderr = std.io.getStdErr().writer();
    nosuspend stderr.print(prefix ++ format ++ "\n", args) catch return;
}

// Public:

pub export fn aether_allocate(size: usize) ?[*]u8 {
    const alloc = allocator() catch return null;
    const res = alloc.alloc(u8, size) catch return null;
    return res.ptr;
}
