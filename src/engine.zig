// Portability notes: None; Code should be platform agnostic.
const std = @import("std");
pub const platform = @import("platform");
pub const Types = @import("types.zig");
pub const Events = @import("core/event.zig");
pub const Util = @import("core/util.zig");
pub const Input = @import("core/input.zig");
pub const Log = @import("core/log.zig");

pub const Options = struct {
    fps: ?u32 = null,
    tps: ?u32 = null,
    ups: ?u32 = null,
    platform: platform.Types.EngineOptions = platform.Types.EngineOptions{},
    json_loaded: bool = false,
    raw: std.json.Parsed(std.json.Value) = undefined,
};

const Application = @import("core/app.zig");

const User = @import("user.zig");

const HookFn = fn (*Options) anyerror!Types.StateInterface;
pub const app_hook: HookFn = User.app_hook;

pub var app_interface: Types.AppInterface = undefined;

pub fn load_options_json() !Options {
    const alloc = Util.allocator();
    var options: Options = Options{};

    var file = try std.fs.cwd().openFile("./options.json", .{});
    Log.info("Loading options.json", .{});
    errdefer {
        file.close();
        Log.warning("Could not open options.json! (Using defaults)", .{});
    }

    defer file.close();

    const file_size = try file.getEndPos();
    const buffer = try alloc.alloc(u8, file_size);
    defer alloc.free(buffer);

    _ = try file.read(buffer);

    const parsed = try std.json.parseFromSlice(std.json.Value, alloc, buffer, .{});
    options.raw = parsed;
    options.json_loaded = true;

    const root = parsed.value.object;

    if (root.get("fps")) |fps_val| {
        options.fps = @intCast(fps_val.integer);
        Log.info("FPS set to {}", .{fps_val.integer});
    }

    if (root.get("tps")) |tps_val| {
        options.tps = @intCast(tps_val.integer);
        Log.info("TPS set to {}", .{tps_val.integer});
    }

    if (root.get("ups")) |ups_val| {
        options.ups = @intCast(ups_val.integer);
        Log.info("UPS set to {}", .{ups_val.integer});
    }

    if (root.get("platform")) |p| {
        const plat = p.object;
        if (plat.get("width")) |width| {
            options.platform.width = @intCast(width.integer);
        }

        if (plat.get("height")) |height| {
            options.platform.height = @intCast(height.integer);
        }

        if (plat.get("title")) |title| {
            options.platform.title = title.string;
        }

        if (plat.get("api")) |api| {
            if (std.mem.eql(u8, api.string, "vulkan")) {
                options.platform.graphics_api = .Vulkan;
            } else if (std.mem.eql(u8, api.string, "opengl")) {
                options.platform.graphics_api = .OpenGL;
            } else if (std.mem.eql(u8, api.string, "gles")) {
                options.platform.graphics_api = .GLES;
            } else {
                Log.warning("Unknown graphics API: {s}", .{api.string});
            }
        }
    }

    return options;
}

pub fn main() !void {
    try platform.base_init();
    Log.info("Calling user hook!", .{});

    var options: Options = try load_options_json();
    const state = try app_hook(&options);

    Log.info("Engine Initialized!", .{});

    try platform.init(options.platform);
    defer platform.deinit();

    try Events.init();
    defer Events.deinit();

    var application = Application.init();
    application.tps = options.tps;
    application.ups = options.ups;
    application.fps = options.fps;
    app_interface = application.interface();

    try app_interface.transition(state);
    application.run();

    if (options.json_loaded) {
        options.raw.deinit();
    }
}
