/// Graphics APIs
pub const GraphicsAPI = enum {
    DirectX11,
    DirectX12,
    GLES32,
    OpenGL15,
    OpenGL46,
    Vulkan10,
    Vulkan13,
};

/// Options for the game engine
pub const EngineOptions = struct {
    title: []const u8,
    width: u16,
    height: u16,
    graphics_api: GraphicsAPI,
};

/// GraphicsEngine is an interface to an underlying Graphics API (Vulkan, OpenGL, etc.)
/// This interface includes the window/screen surface
pub const GraphicsEngine = struct {
    ptr: *anyopaque,
    tab: GraphicsVTable,

    /// Graphics Interface
    pub const GraphicsVTable = struct {
        /// Creates the graphics context with requested window width, height, and title
        /// Some platforms may not support width, height, and title -- these will then have no effect.
        /// This method may return an error for window or context failures.
        init: *const fn (ctx: *anyopaque, width: u16, height: u16, title: []const u8) anyerror!void,

        /// Destroy the graphics context and window
        deinit: *const fn (ctx: *anyopaque) void,

        /// Starts a frame, begins recording commands
        start_frame: *const fn (ctx: *anyopaque) void,

        /// Ends a frame, sends commands to GPU
        end_frame: *const fn (ctx: *anyopaque) void,
    };

    pub fn init(self: GraphicsEngine, width: u16, height: u16, title: []const u8) anyerror!void {
        try self.tab.init(self.ptr, width, height, title);
    }

    pub fn deinit(self: GraphicsEngine) void {
        self.tab.deinit(self.ptr);
    }

    pub fn start_frame(self: GraphicsEngine) void {
        self.tab.start_frame(self.ptr);
    }

    pub fn end_frame(self: GraphicsEngine) void {
        self.tab.start_frame(self.ptr);
    }
};

/// Coerces a pointer `ptr` from *anyopaque to type `*T` for a given `T`.
pub fn coerce_ptr(comptime T: type, ptr: *anyopaque) *T {
    return @as(*T, @ptrCast(@alignCast(ptr)));
}
