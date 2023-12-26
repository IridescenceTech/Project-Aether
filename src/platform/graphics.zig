const allocator = @import("allocator.zig");
const t = @import("types");

const GL46 = @import("GL46.zig");

var engine: t.Platform.GraphicsEngine = undefined;

pub fn init(options: t.Platform.EngineOptions) !void {
    var alloc = try allocator.allocator();
    switch (options.graphics_api) {
        .OpenGL46 => {
            var g = try alloc.create(GL46);
            engine = g.interface();
        },
        else => {
            @panic("Unsupported Graphics API!");
        },
    }

    try engine.init(options.width, options.height, options.title);
}

pub fn get_interface() t.GraphicsEngine {
    return engine;
}
