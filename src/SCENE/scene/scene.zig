const std = @import("std");

pub const Scene = struct {
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) Scene {
        return Scene{
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Scene) void {
        _ = self;
    }

    pub fn setup(self: *Scene) void {
        _ = self;
    }

    pub fn update(self: *Scene, delta_time: f32) void {
        _ = self;
        _ = delta_time;
    }

    pub fn render(self: *Scene) void {
        _ = self;
    }
};
