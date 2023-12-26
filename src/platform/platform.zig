pub const Allocator = @import("allocator.zig");
pub const Graphics = @import("graphics.zig");
const t = @import("types");

pub fn base_init() !void {
    Allocator.init();
}

pub fn init(options: t.Platform.EngineOptions) !void {
    try Graphics.init(options);
}
