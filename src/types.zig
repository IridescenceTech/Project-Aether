const platform = @import("platform");

/// Graphics APIs
pub const GraphicsAPI = enum {
    DirectX,
    GLES,
    OpenGL,
    Vulkan,
};

/// Options for the game engine
pub const EngineOptions = struct {
    title: []const u8,
    width: u16,
    height: u16,
    graphics_api: GraphicsAPI,
};

/// Input Management Interface
pub const InputDescriptor = struct {
    pub const ActionInput = struct {
        id: u16, // ID of the action
        key: platform.Types.Key, // Key to bind to
    };

    pub const Directional = struct {
        analog_priority: u8, // Lower number is higher priority
        id: u8, // ID of the direction
    };

    directional: []Directional,
    action: []ActionInput,
};

/// Input Data
pub const InputResult = struct {
    pub const Direction = struct {
        x: f32,
        y: f32,
        id: u8,
    };

    pub const Action = struct {
        id: u16,
        kind: platform.Types.KeyState,
    };

    directions: []Direction,
    actions: []Action,
};

/// Input State Event
/// This event is used to pass input data to the state
/// The data is a pointer to the state which is being passed
pub const InputStateEvent = struct {
    data: *anyopaque,
    input: InputResult,
};

/// Coerces a pointer `ptr` from *anyopaque to type `*T` for a given `T`.
pub fn coerce_ptr(comptime T: type, ptr: *anyopaque) *T {
    return @as(*T, @ptrCast(@alignCast(ptr)));
}

/// The StateInterface serves as a generic interface to any state using a VTable.
/// The inheriting state object should not assume that any values are initialized.
pub const StateInterface = struct {
    ptr: *anyopaque,
    size: usize,
    tab: StateVTable,

    pub const StateVTable = struct {
        /// on_start() calls the initialization methods.
        /// This method may fail and the transition will not proceed upon failure.
        /// Technical detail: this method occurs before the second state exits.
        /// This method may assume the full engine is initialized
        on_start: *const fn (ctx: *anyopaque) anyerror!void,

        /// on_cleanup() calls the deinitialization methods.
        /// This method cannot fail.
        on_cleanup: *const fn (ctx: *anyopaque) void,

        /// on_update() calls the per update function
        on_update: *const fn (ctx: *anyopaque) void,

        /// on_render() calls the per frame function
        on_render: *const fn (ctx: *anyopaque) void,
    };

    /// Calls the on_start() method for the interface
    pub fn on_start(self: StateInterface) anyerror!void {
        try self.tab.on_start(self.ptr);
    }

    /// Calls the on_cleanup() method for the interface
    pub fn on_cleanup(self: StateInterface) void {
        self.tab.on_cleanup(self.ptr);
    }

    /// Calls the on_update() method for the interface
    pub fn on_update(self: StateInterface) void {
        self.tab.on_update(self.ptr);
    }

    /// Calls the on_render() method for the interface
    pub fn on_render(self: StateInterface) void {
        self.tab.on_render(self.ptr);
    }
};

/// App Interface is the public facing interface for the Application
/// App Interface exposes a VTable and a pointer to the actual application.
pub const AppInterface = struct {
    ptr: *anyopaque,
    tab: AppVTable,

    pub const AppVTable = struct {
        /// Transition takes a given state and transitions the application from
        /// its current state or no state to the new state `state` specified by
        /// the interface. This `state` becomes owned by the Application, regardless
        /// of failure. The StateInterface should be allocated via the util method.
        /// If transition fails, the state object is destroyed, and an error returned.
        transition: *const fn (ctx: *anyopaque, state: StateInterface) anyerror!void,

        /// This quits the application
        quit: *const fn (ctx: *anyopaque) void,
    };

    /// Call the generic transition method on Application
    pub fn transition(app: AppInterface, state: StateInterface) anyerror!void {
        try app.tab.transition(app.ptr, state);
    }

    /// Call the quit method on Application
    pub fn quit(app: AppInterface) void {
        app.tab.quit(app.ptr);
    }
};
