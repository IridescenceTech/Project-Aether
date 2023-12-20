const std = @import("std");
const engine = @import("engine.zig");

pub const std_options = struct {
    pub const log_level = .debug;
    pub const logFn = log;
};

var initialized: bool = false;

var gpa: std.heap.GeneralPurposeAllocator(.{}) = undefined;
pub var allocator: std.mem.Allocator = undefined;

pub fn init() void {
    initialized = true;
    gpa = std.heap.GeneralPurposeAllocator(.{}){};
    allocator = gpa.allocator();
}

/// Creates the state in a defined manner
pub fn allocate_state(comptime T: type) !*T {
    if (!initialized)
        return error.UtilNotInitialized;

    var mem_chunk = try allocator.alignedAlloc(u8, @alignOf(T), @sizeOf(T));
    var t_ptr: *T = @ptrCast(@alignCast(mem_chunk.ptr));
    t_ptr.* = T{};

    return t_ptr;
}

/// Aligns a slice of type T for dealloc
fn make_aligned_slice(comptime T: type) type {
    var tinfo = @typeInfo(T);
    tinfo.Pointer.alignment = 8;
    return @Type(tinfo);
}

/// Deallocates the state in a defined manner
pub fn dealloc_state(state: engine.StateInterface) void {
    var slice: make_aligned_slice([]u8) = undefined;
    slice.ptr = @ptrCast(@alignCast(state.ptr));
    slice.len = state.size;

    allocator.free(slice);
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
