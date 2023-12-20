const std = @import("std");
const engine = @import("engine");
const types = engine.Types;

const SecondState = struct {
    x: usize = 7,

    pub fn on_start(ctx: *anyopaque) anyerror!void {
        _ = ctx;
        std.log.info("Reached second state!", .{});
    }

    pub fn on_cleanup(ctx: *anyopaque) void {
        _ = ctx;
    }
    pub fn on_update(ctx: *anyopaque) void {
        var self = types.coerce_ptr(SecondState, ctx);
        std.log.info("{}", .{self.x});

        self.x -= 1;

        if (self.x == 0) {
            var app_interface = engine.aether_get_app_interface();
            app_interface.quit();
        }
    }
    pub fn on_render(ctx: *anyopaque) void {
        _ = ctx;
    }

    pub fn state(self: *SecondState) types.StateInterface {
        return types.StateInterface{ .ptr = self, .size = @sizeOf(SecondState), .tab = .{
            .on_start = on_start,
            .on_cleanup = on_cleanup,
            .on_render = on_render,
            .on_update = on_update,
        } };
    }
};

const MyState = struct {
    counter: usize = 5,

    pub fn on_start(ctx: *anyopaque) anyerror!void {
        _ = ctx;
        std.log.info("Enter First State!", .{});
    }

    pub fn on_cleanup(ctx: *anyopaque) void {
        std.log.info("Exit First State!", .{});
        _ = ctx;
    }

    pub fn on_update(ctx: *anyopaque) void {
        var self = types.coerce_ptr(MyState, ctx);
        self.counter -= 1;

        if (self.counter == 0) {
            var new_state = engine.Util.allocate(SecondState) catch unreachable;

            var app_interface = engine.aether_get_app_interface();
            app_interface.transition(new_state.state()) catch unreachable;
        }
    }

    pub fn on_render(ctx: *anyopaque) void {
        _ = ctx;
    }

    pub fn interface(self: *MyState) types.StateInterface {
        return types.StateInterface{ .ptr = self, .size = @sizeOf(MyState), .tab = .{
            .on_start = on_start,
            .on_cleanup = on_cleanup,
            .on_render = on_render,
            .on_update = on_update,
        } };
    }
};

pub export fn app_hook(options: *types.EngineOptions) types.StateInterface {
    options.* = types.EngineOptions{
        .title = "My App",
        .width = 1280,
        .height = 720,
    };

    var state = engine.Util.allocate(MyState) catch unreachable;
    return state.interface();
}
