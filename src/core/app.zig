// Portability notes: None; Code should be platform agnostic.

const t = @import("../types.zig");

const log = @import("log.zig");
const util = @import("util.zig");

const Application = @This();

running: bool,
state: ?t.StateInterface,

/// Creates a default state application (running = false, no state)
pub fn init() Application {
    return Application{
        .running = false,
        .state = null,
    };
}

/// Quits the application
fn quit(ctx: *anyopaque) void {
    var self: *Application = @ptrCast(@alignCast(ctx));
    self.running = false;
}

/// Runs the application
pub fn run(self: *Application) void {
    log.info("Starting Application Main Loop!", .{});
    self.running = true;
    while (self.running) {
        if (self.state == null)
            continue;

        self.state.?.on_update();
        self.state.?.on_render();
    }
    log.info("Exiting Application Main Loop!", .{});
}

/// Transitions from a state to another state.
pub fn transition(ctx: *anyopaque, new_state: t.StateInterface) anyerror!void {
    var self: *Application = @ptrCast(@alignCast(ctx));

    new_state.on_start() catch {
        util.dealloc_state(new_state);
        return error.TransitionFailure;
    };

    if (self.state) |state| {
        state.on_cleanup();
        util.dealloc_state(state);
    }

    self.state = new_state;
}

/// Get the Application Interface Object
pub fn interface(self: *Application) t.AppInterface {
    return t.AppInterface{ .ptr = self, .tab = .{
        .quit = quit,
        .transition = transition,
    } };
}
