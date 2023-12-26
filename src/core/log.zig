// Portability notes: `std.io.writer()` and `std.io.getStdErr()` may not always be portable

const std = @import("std");
const builtin = @import("builtin");

/// We define our own Levels
/// Error => Fatal Error
/// Warning => Recoverable Error
/// Info => Information Text
/// Debug => Debugging Text
/// Trace => Verbose Debugging Text
pub const Level = enum(u8) {
    Error = 0,
    Warning = 1,
    Info = 2,
    Debug = 3,
    Trace = 4,

    pub fn to_text(comptime self: Level) []const u8 {
        return @tagName(self);
    }
};

/// By default set the level to Trace in Debug; Info in above
const default_level: Level = switch (builtin.mode) {
    .Debug => .Trace,
    .ReleaseSafe, .ReleaseSmall, .ReleaseFast => .Info,
};

var log_level = default_level;
var fwriter: ?std.fs.File.Writer = null;
var writer_mutex = std.Thread.Mutex{};

/// Set log level
pub fn set_log_level(level: Level) void {
    log_level = level;
}

/// Set file writer
pub fn set_writer(writer: std.io.Writer) void {
    fwriter = writer;
}

/// Log function -- same format as std
pub fn log(
    comptime message_level: Level,
    comptime format: []const u8,
    args: anytype,
) void {
    const level_text = comptime message_level.to_text();
    const prefix = "[" ++ level_text ++ "]: ";

    writer_mutex.lock();
    defer writer_mutex.unlock();

    var writer = fwriter orelse std.io.getStdErr().writer();

    nosuspend writer.print(prefix ++ format ++ "\n", args) catch return;
}

// Bindings

pub fn trace(comptime format: []const u8, args: anytype) void {
    log(.Trace, format, args);
}
pub fn debug(comptime format: []const u8, args: anytype) void {
    log(.Debug, format, args);
}
pub fn info(comptime format: []const u8, args: anytype) void {
    log(.Info, format, args);
}
pub fn warning(comptime format: []const u8, args: anytype) void {
    log(.Warning, format, args);
}
pub fn err(comptime format: []const u8, args: anytype) void {
    log(.Error, format, args);
}

/// Public log interface, allows info reporting from client
/// Takes a string with a given size
pub export fn aether_log(str: [*]const u8, size: usize) void {
    var slice: []const u8 = undefined;
    slice.ptr = str;
    slice.len = size;

    log(.Info, "{s}", .{slice});
}
