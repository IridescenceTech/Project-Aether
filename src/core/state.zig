/// The StateInterface serves as a generic interface to any state using a VTable.
/// The inheriting state object should not assume that engine primitives are initialized.
/// Static member initializations (i.e. variable: usize = 10) are initialized correctly.
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
