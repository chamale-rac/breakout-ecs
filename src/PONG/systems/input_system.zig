const std = @import("std");
const raylib = @import("raylib");
const System = @import("../../ECS/system/system.zig").System;
const World = @import("../../ECS/system/world.zig").World;
const Entity = @import("../../ECS/entity/entity.zig").Entity;
const components = @import("../components/components.zig");

pub const InputSystem = struct {
    base: System,
    screen_width: f32,

    pub fn init(screen_width: f32) InputSystem {
        return InputSystem{
            .base = System.init(),
            .screen_width = screen_width,
        };
    }

    pub fn deinit(self: *InputSystem) void {
        self.base.deinit();
    }

    pub fn setWorld(self: *InputSystem, world: *World) void {
        self.base.setWorld(world);
    }

    pub fn update(self: *InputSystem, delta_time: f32) void {
        if (self.base.world == null) return;

        const world = self.base.world.?;
        const allocator = std.heap.page_allocator;

        // Get all paddle entities
        var paddle_entities = world.getAllEntitiesWith(components.Paddle, allocator) catch return;
        defer paddle_entities.deinit();

        for (paddle_entities.items) |entity| {
            if (world.getComponent(entity, components.Position)) |pos| {
                if (world.getComponent(entity, components.Paddle)) |paddle| {
                    if (world.getComponent(entity, components.Size)) |size| {
                        // Handle input
                        if (raylib.isKeyDown(.left) or raylib.isKeyDown(.a)) {
                            pos.x -= paddle.speed * delta_time;
                        }
                        if (raylib.isKeyDown(.right) or raylib.isKeyDown(.d)) {
                            pos.x += paddle.speed * delta_time;
                        }

                        // Keep paddle within screen bounds
                        if (pos.x < 0) {
                            pos.x = 0;
                        }
                        if (pos.x + size.width > self.screen_width) {
                            pos.x = self.screen_width - size.width;
                        }
                    }
                }
            }
        }
    }
};
