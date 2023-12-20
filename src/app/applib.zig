const engine = @import("engine");
const State = engine.StateInterface;
const EngineOptions = engine.EngineOptions;
const std = @import("std");
const util = engine.util;

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
        var self: *SecondState = @ptrCast(@alignCast(ctx));
        std.log.info("{}", .{self.x});

        self.x -= 1;

        if (self.x == 0) {
            engine.get_app_interface().quit();
        }
    }
    pub fn on_render(ctx: *anyopaque) void {
        _ = ctx;
    }

    pub fn state(self: *SecondState) engine.StateInterface {
        return engine.StateInterface{ .ptr = self, .size = @sizeOf(SecondState), .tab = .{
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

        std.log.info("Entered My State!", .{});
    }

    pub fn on_cleanup(ctx: *anyopaque) void {
        _ = ctx;
        std.log.info("Exiting My State!", .{});
    }

    pub fn on_update(ctx: *anyopaque) void {
        std.log.info("Update!", .{});
        var self: *MyState = @ptrCast(@alignCast(ctx));
        self.counter -= 1;

        if (self.counter == 0) {
            var new_state = util.allocate_state(SecondState) catch unreachable;
            _ = new_state;
            //std.log.info("PTR: {X}", .{engine.get_app_interface()});
            //engine.get_app_interface().transition(new_state.state()) catch unreachable;
        }
    }

    pub fn on_render(ctx: *anyopaque) void {
        _ = ctx;
        std.log.info("Draw!", .{});
    }

    pub fn interface(self: *MyState) engine.StateInterface {
        return engine.StateInterface{ .ptr = self, .size = @sizeOf(MyState), .tab = .{
            .on_start = on_start,
            .on_cleanup = on_cleanup,
            .on_render = on_render,
            .on_update = on_update,
        } };
    }
};

pub export fn app_hook(options: *EngineOptions) State {
    options.* = engine.EngineOptions{
        .title = "My App",
        .width = 1280,
        .height = 720,
    };

    var state = util.allocate_state(MyState) catch unreachable;
    return state.interface();
}
