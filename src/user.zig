const std = @import("std");
const engine = @import("engine.zig");

const MyState = struct {
    pub fn on_start(ctx: *anyopaque) anyerror!void {
        _ = ctx;
        engine.Log.info("Enter First State!", .{});
    }

    pub fn on_cleanup(ctx: *anyopaque) void {
        engine.Log.info("Leave First State!", .{});
        _ = ctx;
    }

    pub fn on_update(ctx: *anyopaque) void {
        _ = ctx;
        engine.Log.info("Update First State!", .{});
    }

    pub fn on_render(ctx: *anyopaque) void {
        _ = ctx;
        engine.Log.info("Render First State!", .{});
    }

    pub fn interface(self: *MyState) engine.Types.StateInterface {
        return engine.Types.StateInterface{ .ptr = self, .size = @sizeOf(MyState), .tab = .{
            .on_start = on_start,
            .on_cleanup = on_cleanup,
            .on_render = on_render,
            .on_update = on_update,
        } };
    }
};

pub fn app_hook(options: *engine.Options) anyerror!engine.Types.StateInterface {
    options.* = .{
        .title = "Hello, World!",
        .width = 800,
        .height = 600,
        .graphics_api = .OpenGL,
    };
    engine.Log.info("app_hook called", .{});

    var state = engine.Util.alloc_state(MyState) catch unreachable;
    return state.interface();
}
