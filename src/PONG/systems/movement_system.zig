const std = @import("std");
const System = @import("../../ECS/system/system.zig").System;
const World = @import("../../ECS/system/world.zig").World;
const Entity = @import("../../ECS/entity/entity.zig").Entity;
const components = @import("../components/components.zig");

pub const MovementSystem = struct {
    base: System,

    pub fn init() MovementSystem {
        return MovementSystem{
            .base = System.init(),
        };
    }

    pub fn deinit(self: *MovementSystem) void {
        self.base.deinit();
    }

    pub fn setWorld(self: *MovementSystem, world: *World) void {
        self.base.setWorld(world);
    }

    pub fn update(self: *MovementSystem, delta_time: f32) void {
        if (self.base.world == null) return;

        const world = self.base.world.?;
        const allocator = std.heap.page_allocator;

        // Get all entities with position and velocity
        var entities_with_velocity = world.getAllEntitiesWith(components.Velocity, allocator) catch return;
        defer entities_with_velocity.deinit();

        for (entities_with_velocity.items) |entity| {
            if (world.hasComponent(entity, components.Position)) {
                if (world.getComponent(entity, components.Position)) |pos| {
                    if (world.getComponent(entity, components.Velocity)) |vel| {
                        pos.x += vel.x * delta_time;
                        pos.y += vel.y * delta_time;
                    }
                }
            }
        }
    }
};
