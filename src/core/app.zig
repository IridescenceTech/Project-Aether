const StateInterface = @import("state.zig").StateInterface;

/// App Interface is the public facing interface for the Application
/// App Interface exposes a VTable and a pointer to the actual application.
const AppInterface = @This();

ptr: *anyopaque,
tab: AppVTable,

pub const AppVTable = struct {
    /// Transition takes a given state and transitions the application from
    /// its current state or no state to the new state `state` specified by
    /// the interface. The StateInterface should be derived from the util
    /// allocated state for consistency
    transition: *const fn (ctx: *anyopaque, state: StateInterface) anyerror!void,

    /// This quits the application
    quit: *const fn (ctx: *anyopaque) void,
};

/// Call the generic transition method on Application
pub fn transition(app: AppInterface, state: StateInterface) anyerror!void {
    try app.tab.transition(app.ptr, state);
}

/// Call the quit method on Application
pub fn quit(app: AppInterface) void {
    app.tab.quit(app.ptr);
}
