// Portability notes: None; Code should be platform agnostic.

const std = @import("std");
const platform = @import("platform");
const t = @import("../types.zig");

const log = @import("log.zig");
const util = @import("util.zig");

const Application = @import("app.zig");

pub fn main() !void {
    // TODO: Platform Init(?) / Base Init
    try platform.base_init();
    log.info("Calling user hook!", .{});

    var options: t.Platform.EngineOptions = undefined;
    var state = app_hook(&options);

    log.info("Engine Initialized!", .{});
    //TODO: Actually initalize the engine.
    try platform.init(options);

    var application = Application.init();
    app_interface = application.interface();

    try app_interface.transition(state);
    application.run();
}

/// External hook to the user code
extern fn app_hook(opt: *t.Platform.EngineOptions) callconv(.C) t.StateInterface;

/// App interface
var app_interface: t.AppInterface = undefined;
pub export fn aether_get_app_interface() t.AppInterface {
    return app_interface;
}
