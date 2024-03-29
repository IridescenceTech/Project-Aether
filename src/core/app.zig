// Portability notes: None; Code should be platform agnostic.
const std = @import("std");
const t = @import("../types.zig");

const Events = @import("event.zig");
const log = @import("log.zig");
const util = @import("util.zig");
const platform = @import("platform");
const input = @import("input.zig");

const Application = @This();

running: bool,
state: ?t.StateInterface,
fps: ?u32,
tps: ?u32,
ups: ?u32,

/// Creates a default state application (running = false, no state)
pub fn init() Application {
    try input.init();
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
    var fps_nanos: u64 = 0;
    var fps_report: u64 = 0;
    var tps_counter: u64 = 0;
    var ups_counter: u64 = 0;

    while (self.running) {
        curr_nanos = std.time.nanoTimestamp();
        fps_counter += @intCast(curr_nanos - last_nanos);
        tps_counter += @intCast(curr_nanos - last_nanos);
        ups_counter += @intCast(curr_nanos - last_nanos);
        fps_nanos += @intCast(curr_nanos - last_nanos);

        last_nanos = curr_nanos;

        if (self.state == null)
            continue;

        const should_fps = self.fps == null or (self.fps != null and fps_counter >= nanoseconds_per_second / self.fps.?);
        if (should_fps) {
            if (self.fps != null) {
                fps_counter = 0;
            }

            const g = platform.Graphics.get_interface();
            fps_report += 1;

            g.start_frame();
            Events.publish(
                Events.RenderChannel,
                Events.Event{ .id = Events.RenderChannel, .data = self },
            );
            g.end_frame();
        }

        if (fps_nanos >= nanoseconds_per_second) {
            fps_nanos = 0;
            log.debug("FPS: {}", .{fps_report});
            fps_report = 0;
        }

        const should_tps = self.tps == null or (self.tps != null and tps_counter >= nanoseconds_per_second / self.tps.?);
        if (should_tps) {
            if (self.tps != null) {
                tps_counter = 0;
            }

            Events.publish(
                Events.TickChannel,
                Events.Event{ .id = Events.TickChannel, .data = self },
            );
        }

        const should_ups = self.ups == null or (self.ups != null and ups_counter >= nanoseconds_per_second / self.ups.?);
        if (should_ups) {
            if (self.ups != null) {
                ups_counter = 0;
            }

            Events.publish(
                Events.UpdateChannel,
                Events.Event{ .id = Events.UpdateChannel, .data = self },
            );
            platform.poll_events();
            if (input.get_input_result()) |result| {
                if (self.state != null) {
                    var event = t.InputStateEvent{
                        .data = self.state.?.ptr,
                        .input = result,
                    };
                    Events.publish(
                        Events.InputChannel,
                        Events.Event{ .id = Events.InputChannel, .data = &event },
                    );
                }
            }
        }

        if (platform.Graphics.get_interface().should_close()) {
            self.running = false;
        }
    }

    Events.unsubscribe(Events.UpdateChannel, update);
    Events.unsubscribe(Events.RenderChannel, render);

    if (self.state) |state| {
        state.on_cleanup();
        util.dealloc_state(state);
    }

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
