const std = @import("std");
const log = std.log;

const t = @import("types.zig");
const util = @import("util.zig");

pub const std_options = util.std_options;

/// External hook to the user code
extern fn app_hook(opt: *t.EngineOptions) callconv(.C) t.StateInterface;

const Application = struct {
    running: bool,
    state: ?t.StateInterface,

    pub fn init() Application {
        return Application{
            .running = false,
            .state = null,
        };
    }

    fn quit(ctx: *anyopaque) void {
        var self: *Application = @ptrCast(@alignCast(ctx));
        self.running = false;
    }

    pub fn run(self: *Application) void {
        self.running = true;
        while (self.running) {
            if (self.state == null)
                continue;

            self.state.?.on_update();
            self.state.?.on_render();
        }
    }

    pub fn transition(ctx: *anyopaque, new_state: t.StateInterface) anyerror!void {
        var self: *Application = @ptrCast(@alignCast(ctx));

        if (self.state) |state| {
            state.on_cleanup();
            util.dealloc_state(state);
        }

        self.state = new_state;
        try new_state.on_start();
    }

    pub fn interface(self: *Application) t.AppInterface {
        return t.AppInterface{ .ptr = self, .tab = .{
            .quit = quit,
            .transition = transition,
        } };
    }
};

var app_interface: t.AppInterface = undefined;

pub fn main() !void {
    // TODO: Platform Init(?) / Base Init
    util.init();
    log.info("Calling into hookland!", .{});

    var options: t.EngineOptions = undefined;
    var state = app_hook(&options);

    log.info("Project Aether Initialize!", .{});
    //TODO: Actually initalize the engine.

    var application = Application.init();
    app_interface = application.interface();

    try app_interface.transition(state);
    application.run();
}

pub export fn aether_get_app_interface() t.AppInterface {
    return app_interface;
}
