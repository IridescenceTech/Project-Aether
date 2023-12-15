const std = @import("std");
const engine = @import("engine.zig");
const util = @import("util.zig");

pub const std_options = util.std_options;

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
            engine.app_instance.quit();
        }
    }
    pub fn on_render(ctx: *anyopaque) void {
        _ = ctx;
    }

    pub fn state(self: *SecondState) engine.StateInstance {
        return engine.StateInstance{ .ptr = self, .size = @sizeOf(SecondState), .tab = .{
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
            engine.app_instance.transition(new_state.state()) catch unreachable;
        }
    }

    pub fn on_render(ctx: *anyopaque) void {
        _ = ctx;
        std.log.info("Draw!", .{});
    }

    pub fn state(self: *MyState) engine.StateInstance {
        return engine.StateInstance{ .ptr = self, .size = @sizeOf(MyState), .tab = .{
            .on_start = on_start,
            .on_cleanup = on_cleanup,
            .on_render = on_render,
            .on_update = on_update,
        } };
    }
};

pub fn main() !void {
    const options = engine.EngineOptions{
        .title = "My App",
        .width = 1280,
        .height = 720,
    };

    util.init();

    var state = try util.allocate_state(MyState);
    try engine.init(options, state.state());
}
