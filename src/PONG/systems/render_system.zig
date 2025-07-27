const std = @import("std");
const raylib = @import("raylib");
const System = @import("../../ECS/system/system.zig").System;
const World = @import("../../ECS/system/world.zig").World;
const Entity = @import("../../ECS/entity/entity.zig").Entity;
const components = @import("../components/components.zig");

pub const RenderSystem = struct {
    base: System,

    pub fn init() RenderSystem {
        return RenderSystem{
            .base = System.init(),
        };
    }

    pub fn deinit(self: *RenderSystem) void {
        self.base.deinit();
    }

    pub fn setWorld(self: *RenderSystem, world: *World) void {
        self.base.setWorld(world);
    }

    pub fn render(self: *RenderSystem) void {
        if (self.base.world == null) return;

        const world = self.base.world.?;
        const allocator = std.heap.page_allocator;

        // Render all renderable entities
        var renderable_entities = world.getAllEntitiesWith(components.Renderable, allocator) catch return;
        defer renderable_entities.deinit();

        for (renderable_entities.items) |entity| {
            if (world.getComponent(entity, components.Renderable)) |renderable| {
                if (renderable.visible) {
                    if (world.getComponent(entity, components.Position)) |pos| {
                        if (world.getComponent(entity, components.Size)) |size| {
                            if (world.getComponent(entity, components.Color)) |color| {
                                // Check if it's a block that's destroyed
                                var should_render = true;
                                if (world.getComponent(entity, components.Block)) |block| {
                                    should_render = !block.destroyed;
                                }

                                if (should_render) {
                                    raylib.drawRectangle(@intFromFloat(pos.x), @intFromFloat(pos.y), @intFromFloat(size.width), @intFromFloat(size.height), color.toRaylib());
                                }
                            }
                        }
                    }
                }
            }
        }
    }
};
