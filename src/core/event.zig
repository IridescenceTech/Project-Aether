const std = @import("std");
const util = @import("util.zig");

pub const ChannelIndex = u16;

pub const Event = struct {
    id: ChannelIndex,
    data: *anyopaque,
};
pub const EventList = std.ArrayList(Event);

pub const Subscriber = *const fn (event: Event) void;
pub const SubscriberList = std.ArrayList(Subscriber);

const Channel = struct {
    id: ChannelIndex = 0,
    subscribers: SubscriberList = undefined,
};

const ChannelList = std.ArrayList(Channel);

var channels: ChannelList = undefined;
pub var UpdateChannel: ChannelIndex = undefined;
pub var RenderChannel: ChannelIndex = undefined;
pub var InputChannel: ChannelIndex = undefined;
pub var TickChannel: ChannelIndex = undefined;

pub fn init() !void {
    const alloc = util.allocator();
    channels = ChannelList.init(alloc);

    UpdateChannel = add_channel();
    RenderChannel = add_channel();
    InputChannel = add_channel();
    TickChannel = add_channel();
}

pub fn deinit() void {
    for (channels.items) |*channel| {
        channel.subscribers.clearAndFree();
    }
    channels.deinit();
}

pub fn add_channel() ChannelIndex {
    const channel = Channel{
        .id = @truncate(channels.items.len),
        .subscribers = SubscriberList.init(util.allocator()),
    };
    channels.append(channel) catch unreachable;
    return channel.id;
}

pub fn subscribe(channel: ChannelIndex, subscriber: Subscriber) void {
    const chan = &channels.items[channel];
    chan.subscribers.append(subscriber) catch unreachable;
}

pub fn unsubscribe(channel: ChannelIndex, subscriber: Subscriber) void {
    const chan = &channels.items[channel];

    var index: usize = 0;
    for (chan.subscribers.items, 0..) |item, i| {
        if (item == subscriber) {
            index = i;
            break;
        }
    }

    _ = chan.subscribers.swapRemove(index);
}

pub fn publish(channel: ChannelIndex, event: Event) void {
    const chan = &channels.items[channel];
    for (chan.subscribers.items) |subscriber| {
        subscriber(event);
    }
}

pub const EventManager = struct {
    subscribers: []Subscriber,
    subscribe: fn (subscriber: Subscriber) void,
    unsubscribe: fn (subscriber: Subscriber) void,
    publish: fn (event: Event) void,
};
