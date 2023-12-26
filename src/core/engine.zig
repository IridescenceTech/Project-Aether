const std = @import("std");
const t = @import("types");

const log = @import("log.zig");
const util = @import("util.zig");

const Application = @import("app.zig");

pub fn main() !void {
    // TODO: Platform Init(?) / Base Init
    util.init();
    log.info("Calling user hook!", .{});

    var options: t.EngineOptions = undefined;
    var state = app_hook(&options);

    log.info("Engine Initialized!", .{});
    //TODO: Actually initalize the engine.

    var application = Application.init();
    app_interface = application.interface();

    try app_interface.transition(state);
    application.run();
}

/// External hook to the user code
extern fn app_hook(opt: *t.EngineOptions) callconv(.C) t.StateInterface;

/// App interface
var app_interface: t.AppInterface = undefined;
pub export fn aether_get_app_interface() t.AppInterface {
    return app_interface;
}
