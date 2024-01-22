// Portability notes: None; Code should be platform agnostic.
const std = @import("std");
pub const platform = @import("platform");
pub const Types = @import("types.zig");
pub const Events = @import("core/event.zig");
pub const Util = @import("core/util.zig");
pub const Log = @import("core/log.zig");
pub const Options = platform.Types.EngineOptions;

const Application = @import("core/app.zig");

const User = @import("user.zig");

const HookFn = fn (*Options) anyerror!Types.StateInterface;
pub const app_hook: HookFn = User.app_hook;

pub var app_interface: Types.AppInterface = undefined;

pub fn main() !void {
    try platform.base_init();
    Log.info("Calling user hook!", .{});

    var options: Options = undefined;
    const state = try app_hook(&options);

    Log.info("Engine Initialized!", .{});

    try Events.init();
    defer Events.deinit();

    try platform.init(options);
    defer platform.deinit();

    var application = Application.init();
    app_interface = application.interface();

    try app_interface.transition(state);
    application.run();
}
