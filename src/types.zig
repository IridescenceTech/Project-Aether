/// Options for the game engine
pub const EngineOptions = struct {
    title: []const u8,
    width: u32,
    height: u32,
};

/// The StateInterface serves as a generic interface to any state using a VTable.
/// The inheriting state object should not assume that any values are initialized.
pub const StateInterface = extern struct {
    ptr: *anyopaque,
    size: usize,
    tab: StateVTable,

    pub const StateVTable = extern struct {
        /// on_start() calls the initialization methods.
        /// This method may fail and the transition will not proceed upon failure.
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
pub const AppInterface = extern struct {
    ptr: *anyopaque,
    tab: AppVTable,

    pub const AppVTable = extern struct {
        /// Transition takes a given state and transitions the application from
        /// its current state or no state to the new state `state` specified by
        /// the interface. The StateInterface should be derived from the util
        /// allocated state for consistency
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
