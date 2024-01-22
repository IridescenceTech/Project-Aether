// Portability notes: None; Code should be platform agnostic.
const std = @import("std");
const t = @import("../types.zig");

const Events = @import("event.zig");
const log = @import("log.zig");
const util = @import("util.zig");
const platform = @import("platform");

const Application = @This();

running: bool,
state: ?t.StateInterface,
fps: ?u32,
tps: ?u32,
ups: ?u32,

/// Creates a default state application (running = false, no state)
pub fn init() Application {
    return Application{
        .running = false,
        .state = null,
        .tps = null,
        .fps = null,
        .ups = null,
    };
}

fn update(event: Events.Event) void {
    var self: *Application = @ptrCast(@alignCast(event.data));
    if (self.state == null)
        return;

    self.state.?.on_update();
}

fn render(event: Events.Event) void {
    var self: *Application = @ptrCast(@alignCast(event.data));
    if (self.state == null)
        return;

    self.state.?.on_render();
}

/// Quits the application
fn quit(ctx: *anyopaque) void {
    var self: *Application = @ptrCast(@alignCast(ctx));
    self.running = false;
}

/// Runs the application
pub fn run(self: *Application) void {
    log.info("Starting Application Main Loop!", .{});
    self.running = true;

    Events.subscribe(Events.UpdateChannel, update);
    Events.subscribe(Events.RenderChannel, render);

    const nanoseconds_per_second: u64 = 1_000_000_000;
    var curr_nanos = std.time.nanoTimestamp();
    var last_nanos = std.time.nanoTimestamp();
    var fps_counter: u64 = 0;
    var tps_counter: u64 = 0;
    var ups_counter: u64 = 0;

    while (self.running) {
        curr_nanos = std.time.nanoTimestamp();
        fps_counter += @intCast(curr_nanos - last_nanos);
        tps_counter += @intCast(curr_nanos - last_nanos);
        ups_counter += @intCast(curr_nanos - last_nanos);

        last_nanos = curr_nanos;

        if (self.state == null)
            continue;

        if (self.fps) |fps| {
            if (fps_counter >= nanoseconds_per_second / fps) {
                fps_counter = 0;

                const g = platform.Graphics.get_interface();
                g.start_frame();

                Events.publish(
                    Events.RenderChannel,
                    Events.Event{ .id = Events.RenderChannel, .data = self },
                );

                g.end_frame();
            }
        } else {
            const g = platform.Graphics.get_interface();

            g.start_frame();
            Events.publish(
                Events.RenderChannel,
                Events.Event{ .id = Events.RenderChannel, .data = self },
            );
            g.end_frame();
        }

        if (self.tps) |tps| {
            if (tps_counter >= nanoseconds_per_second / tps) {
                tps_counter = 0;
                Events.publish(
                    Events.TickChannel,
                    Events.Event{ .id = Events.UpdateChannel, .data = self },
                );
            }
        } else {
            Events.publish(
                Events.TickChannel,
                Events.Event{ .id = Events.UpdateChannel, .data = self },
            );
        }

        if (self.ups) |ups| {
            if (ups_counter >= nanoseconds_per_second / ups) {
                ups_counter = 0;
                Events.publish(
                    Events.UpdateChannel,
                    Events.Event{ .id = Events.UpdateChannel, .data = self },
                );
                platform.poll_events();
            }
        } else {
            Events.publish(
                Events.UpdateChannel,
                Events.Event{ .id = Events.UpdateChannel, .data = self },
            );
            platform.poll_events();
        }

        if (platform.Graphics.get_interface().should_close()) {
            self.running = false;
        }
    }

    Events.unsubscribe(Events.UpdateChannel, update);
    Events.unsubscribe(Events.RenderChannel, render);
    log.info("Exiting Application Main Loop!", .{});
}

/// Transitions from a state to another state.
pub fn transition(ctx: *anyopaque, new_state: t.StateInterface) anyerror!void {
    var self: *Application = @ptrCast(@alignCast(ctx));

    new_state.on_start() catch {
        util.dealloc_state(new_state);
        return error.TransitionFailure;
    };

    if (self.state) |state| {
        state.on_cleanup();
        util.dealloc_state(state);
    }

    self.state = new_state;
}

/// Get the Application Interface Object
pub fn interface(self: *Application) t.AppInterface {
    return t.AppInterface{ .ptr = self, .tab = .{
        .quit = quit,
        .transition = transition,
    } };
}
