// Portability notes: None; Code should be platform agnostic.

const std = @import("std");
const platform = @import("platform");
pub const Types = @import("types.zig");

pub const Options = platform.Types.EngineOptions;

const log = @import("core/log.zig");
const util = @import("core/util.zig");

const Application = @import("core/app.zig");

const User = @import("user");

const HookFn = fn (*Options) anyerror!Types.StateInterface;
pub const app_hook: HookFn = User.app_hook;

pub var app_interface: Types.AppInterface = undefined;

pub fn main() !void {
    try platform.base_init();
    log.info("Calling user hook!", .{});

    var options: Options = undefined;
    const state = try app_hook(&options);

    log.info("Engine Initialized!", .{});
    try platform.init(options);

    var application = Application.init();
    app_interface = application.interface();

    try app_interface.transition(state);
    application.run();
}
