const std = @import("std");
const World = @import("world.zig").World;

pub const System = struct {
    world: ?*World,

    pub fn init() System {
        return System{
            .world = null,
        };
    }

    pub fn deinit(self: *System) void {
        _ = self;
    }

    pub fn setWorld(self: *System, world: *World) void {
        self.world = world;
    }

    pub fn setup(self: *System) void {
        _ = self;
    }

    pub fn update(self: *System, delta_time: f32) void {
        _ = self;
        _ = delta_time;
    }

    pub fn render(self: *System) void {
        _ = self;
    }
};
