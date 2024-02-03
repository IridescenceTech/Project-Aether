const std = @import("std");
const engine = @import("engine.zig");

const Vertex = struct {
    pub const Layout = engine.platform.Types.VertexLayout{
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

const MyState = struct {
    tex: engine.platform.Types.Texture = undefined,
    mesh: engine.platform.Types.Mesh(Vertex, Vertex.Layout) = undefined,

    pub fn on_start(ctx: *anyopaque) anyerror!void {
        var self = engine.Types.coerce_ptr(MyState, ctx);

        var g = engine.platform.Graphics.get_interface();

        self.tex = g.load_texture("container.jpg");
        g.set_texture(self.tex);

        self.mesh = try engine.platform.Types.Mesh(Vertex, Vertex.Layout).init();
        self.mesh.deinit();

        try self.mesh.vertices.appendSlice(&[_]Vertex{
            .{ .pos = [_]f32{ -0.5, -0.5, 0.5 }, .color = 0xFF0000FF, .texture = [_]f32{ 0.0, 0.0 } },
            .{ .pos = [_]f32{ 0.5, -0.5, 0.5 }, .color = 0xFFFF0000, .texture = [_]f32{ 1.0, 0.0 } },
            .{ .pos = [_]f32{ 0.5, 0.5, 0.5 }, .color = 0xFF00FF00, .texture = [_]f32{ 1.0, 1.0 } },
            .{ .pos = [_]f32{ -0.5, 0.5, 0.5 }, .color = 0xFF0000FF, .texture = [_]f32{ 0.0, 1.0 } },
        });

        try self.mesh.indices.appendSlice(&[_]u16{ 0, 1, 2, 2, 3, 0 });

        self.mesh.update();
    }

    pub fn on_cleanup(ctx: *anyopaque) void {
        var self = engine.Types.coerce_ptr(MyState, ctx);
        self.mesh.deinit();
    }

    pub fn on_update(ctx: *anyopaque) void {
        _ = ctx;
    }

    pub fn on_render(ctx: *anyopaque) void {
        var self = engine.Types.coerce_ptr(MyState, ctx);
        self.mesh.draw();
    }

    pub fn interface(self: *MyState) engine.Types.StateInterface {
        return engine.Types.StateInterface{ .ptr = self, .size = @sizeOf(MyState), .tab = .{
            .on_start = on_start,
            .on_cleanup = on_cleanup,
            .on_render = on_render,
            .on_update = on_update,
        } };
    }
};

pub fn app_hook(options: *engine.Options) anyerror!engine.Types.StateInterface {
    options.tps = 20;
    engine.Log.info("app_hook called", .{});

    var state = engine.Util.alloc_state(MyState) catch unreachable;
    return state.interface();
}
