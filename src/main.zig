const std = @import("std");
const platform = @import("platform");

const Vertex = struct {
    pub const Layout = platform.Types.VertexLayout{
        .size = @sizeOf(Vertex),
        .vertex = .{
            .dimensions = 3,
            .backing_type = .Float,
            .offset = 0,
            .normalize = false,
        },
        .color = .{
            .dimensions = 4,
            .backing_type = .UByte,
            .offset = 12,
            .normalize = true,
        },
        .texture = .{
            .dimensions = 2,
            .backing_type = .Float,
            .offset = 16,
            .normalize = false,
        },
    };

    pos: [3]f32,
    color: u32,
    texture: [2]f32,
};

pub fn main() !void {
    try platform.base_init();

    try platform.init(.{
        .width = 960,
        .height = 544,
        .title = "Hello, World!",
        .graphics_api = .Vulkan,
    });
    std.log.info("Hello, World!", .{});

    defer platform.deinit();

    var g = platform.Graphics.get_interface();

    const tex = g.load_texture("container.jpg");
    g.set_texture(tex);

    var mesh = try platform.Types.Mesh(Vertex, Vertex.Layout).init();
    defer mesh.deinit();

    try mesh.vertices.appendSlice(&[_]Vertex{
        .{ .pos = [_]f32{ -0.5, -0.5, 0.5 }, .color = 0xFF0000FF, .texture = [_]f32{ 0.0, 0.0 } },
        .{ .pos = [_]f32{ 0.5, -0.5, 0.5 }, .color = 0xFFFF0000, .texture = [_]f32{ 1.0, 0.0 } },
        .{ .pos = [_]f32{ 0.5, 0.5, 0.5 }, .color = 0xFF00FF00, .texture = [_]f32{ 1.0, 1.0 } },
        .{ .pos = [_]f32{ -0.5, 0.5, 0.5 }, .color = 0xFF0000FF, .texture = [_]f32{ 0.0, 1.0 } },
    });

    try mesh.indices.appendSlice(&[_]u16{ 0, 1, 2, 2, 3, 0 });

    mesh.update();

    var curr_time = std.time.milliTimestamp();
    var fps_time = std.time.nanoTimestamp();
    var fps: usize = 0;
    while (!g.should_close()) {
        const new_time = std.time.milliTimestamp();
        if (new_time - curr_time > 1000 / 144) {
            platform.poll_events();
            curr_time = new_time;
        }

        const fp_time = std.time.nanoTimestamp();
        if (fp_time - fps_time > 1_000_000_000) {
            fps_time = fp_time;
            std.log.err("FPS: {}", .{fps});
            fps = 0;
        }

        fps += 1;

        g.start_frame();
        mesh.draw();
        g.end_frame();
    }
}
