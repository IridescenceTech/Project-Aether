const std = @import("std");
const engine = @import("engine");

pub fn app_hook(option: *engine.Options) anyerror!engine.Types.StateInterface {
    _ = option; // autofix
    return error.Unimplemented;
}
