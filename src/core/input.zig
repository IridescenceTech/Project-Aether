// Portability notes: None; Code should be platform agnostic.
const std = @import("std");
const t = @import("../types.zig");

const Events = @import("event.zig");
const log = @import("log.zig");
const util = @import("util.zig");
const platform = @import("platform");

var input_descriptor: ?t.InputDescriptor = null;

pub fn init() !void {
    input_descriptor = null;
}

pub fn set_input_mode(mode: t.InputDescriptor) void {
    input_descriptor = mode;
}

// pub const Key = enum(u16) {
//     Up,
//     Down,
//     Left,
//     Right,

//     LButton,
//     RButton,

//     Jump,
//     Attack,
//     Cancel,
//     Menu,
// };

// pub const ActionInput = struct {
//     id: u16,
//     key: Key,
// };

// pub const Directional = struct {
//     analog_priority: u8,
//     id: u8,
// };

// directional: []Directional,
// action: []ActionInput,

pub fn get_input_result() ?t.InputResult {
    if (input_descriptor) |descriptor| {
        var result: t.InputResult = undefined;

        const allocator = util.allocator();
        var dir_array = std.ArrayList(t.InputResult.Direction).init(allocator);
        defer dir_array.deinit();

        var actions_array = std.ArrayList(t.InputResult.Action).init(allocator);
        defer actions_array.deinit();

        for (descriptor.directional) |directional| {
            var analog_res: platform.Types.AnalogResult = undefined;
            if (directional.analog_priority > platform.get_number_analogs()) {
                analog_res = platform.get_analog_state(0xFF);
            } else {
                analog_res = platform.get_analog_state(directional.analog_priority);
            }

            dir_array.append(.{ .id = directional.id, .x = analog_res.x, .y = analog_res.y }) catch unreachable;
        }

        for (descriptor.action) |action| {
            const key_res = platform.get_key_state(action.key);
            actions_array.append(.{ .id = action.id, .kind = key_res }) catch unreachable;
        }

        result.directions = dir_array.toOwnedSlice() catch unreachable;
        result.actions = actions_array.toOwnedSlice() catch unreachable;

        return result;
    } else {
        return null;
    }
}

pub fn deinit() void {
    input_descriptor = null;
}
