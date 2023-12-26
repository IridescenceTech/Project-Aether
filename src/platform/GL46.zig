const t = @import("types");
const glfw = @import("glfw");
const Self = @This();

pub fn init(ctx: *anyopaque, width: u16, height: u16, title: []const u8) anyerror!void {
    _ = title;
    _ = height;
    _ = width;
    _ = ctx;
}

pub fn deinit(ctx: *anyopaque) void {
    _ = ctx;
}

pub fn start_frame(ctx: *anyopaque) void {
    _ = ctx;
}

pub fn end_frame(ctx: *anyopaque) void {
    _ = ctx;
}

pub fn interface(self: *Self) t.Platform.GraphicsEngine {
    return .{
        .ptr = self,
        .tab = .{
            .init = init,
            .deinit = deinit,
            .start_frame = start_frame,
            .end_frame = end_frame,
        },
    };
}
