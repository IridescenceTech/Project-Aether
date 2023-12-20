const std = @import("std");
const log = std.log;
const AppInterface = @import("core/app.zig");

pub const util = @import("util.zig");
pub const std_options = util.std_options;
pub const StateInterface = @import("core/state.zig").StateInterface;

/// Options for the game engine
pub const EngineOptions = struct {
    title: []const u8,
    width: u32,
    height: u32,
};

/// External hook to the user code
extern fn app_hook(opt: *EngineOptions) callconv(.C) StateInterface;

const Application = struct {
    running: bool,
    state: ?StateInterface,

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

    pub fn transition(ctx: *anyopaque, new_state: StateInterface) anyerror!void {
        var self: *Application = @ptrCast(@alignCast(ctx));

        if (self.state) |state| {
            state.on_cleanup();
            util.dealloc_state(state);
        }

        self.state = new_state;
        try new_state.on_start();
    }

    pub fn interface(self: *Application) AppInterface {
        return AppInterface{ .ptr = self, .tab = .{
            .quit = quit,
            .transition = transition,
        } };
    }
};

pub fn main() !void {
    // TODO: Platform Init(?) / Base Init
    util.init();

    var options: EngineOptions = undefined;
    var state = app_hook(&options);

    try init(options, state);
}

fn init(options: EngineOptions, state: StateInterface) !void {
    log.info("Project Aether Initialize!", .{});
    _ = options;
    //TODO: Actually initalize the engine.

    var application = Application.init();
    var app_interface = application.interface();

    try app_interface.transition(state);
    application.run();
}
