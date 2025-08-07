const std = @import("std");
const EntityModule = @import("../entity/entity.zig");
const Entity = EntityModule.Entity;
const ComponentStorage = @import("../components/component.zig").ComponentStorage;
const getComponentTypeId = @import("../components/component.zig").getComponentTypeId;

pub const World = struct {
    allocator: std.mem.Allocator,
    next_entity_id: EntityModule.EntityId,
    free_entities: std.ArrayList(EntityModule.EntityId),
    component_storages: std.ArrayList(ComponentStorage),
    component_type_ids: std.ArrayList(u32),

    pub fn init(allocator: std.mem.Allocator) World {
        return World{
            .allocator = allocator,
            .next_entity_id = 0,
            .free_entities = std.ArrayList(EntityModule.EntityId).init(allocator),
            .component_storages = std.ArrayList(ComponentStorage).init(allocator),
            .component_type_ids = std.ArrayList(u32).init(allocator),
        };
    }

    pub fn deinit(self: *World) void {
        for (self.component_storages.items) |*storage| {
            storage.deinit();
        }
        self.component_storages.deinit();
        self.component_type_ids.deinit();
        self.free_entities.deinit();
    }

    pub fn createEntity(self: *World) Entity {
        const entity_id = if (self.free_entities.items.len > 0)
            self.free_entities.pop().?
        else blk: {
            const id = self.next_entity_id;
            self.next_entity_id += 1;
            break :blk id;
        };

        return Entity.init(entity_id);
    }

    pub fn destroyEntity(self: *World, entity: Entity) void {
        // Remove all components for this entity
        for (self.component_storages.items) |*storage| {
            storage.removeComponent(entity.id);
        }

        // Add to free list
        self.free_entities.append(entity.id) catch {};
    }

    pub fn addComponent(self: *World, entity: Entity, comptime T: type, component: T) !void {
        const type_id = getComponentTypeId(T);

        // Find existing storage or create new one
        var storage_index: ?usize = null;
        for (self.component_type_ids.items, 0..) |stored_type_id, i| {
            if (stored_type_id == type_id) {
                storage_index = i;
                break;
            }
        }

        if (storage_index == null) {
            // Create new storage
            try self.component_type_ids.append(type_id);
            try self.component_storages.append(ComponentStorage.init(self.allocator, @sizeOf(T)));
            storage_index = self.component_storages.items.len - 1;
        }

        // Convert component to bytes and ensure correct size
        const component_bytes = std.mem.asBytes(&component);
        if (component_bytes.len != @sizeOf(T)) {
            std.debug.print("ComponentSizeMismatch for type {s}: expected {}, got {}\n", .{ @typeName(T), @sizeOf(T), component_bytes.len });
            return error.ComponentSizeMismatch;
        }
        try self.component_storages.items[storage_index.?].addComponent(entity.id, component_bytes);
    }

    pub fn removeComponent(self: *World, entity: Entity, comptime T: type) void {
        const type_id = getComponentTypeId(T);
        for (self.component_type_ids.items, 0..) |stored_type_id, i| {
            if (stored_type_id == type_id) {
                self.component_storages.items[i].removeComponent(entity.id);
                break;
            }
        }
    }

    pub fn getComponent(self: *World, entity: Entity, comptime T: type) ?*T {
        const type_id = getComponentTypeId(T);
        for (self.component_type_ids.items, 0..) |stored_type_id, i| {
            if (stored_type_id == type_id) {
                if (self.component_storages.items[i].getComponent(entity.id)) |component_bytes| {
                    return @ptrCast(@alignCast(component_bytes.ptr));
                }
                break;
            }
        }
        return null;
    }

    pub fn hasComponent(self: *World, entity: Entity, comptime T: type) bool {
        const type_id = getComponentTypeId(T);
        for (self.component_type_ids.items, 0..) |stored_type_id, i| {
            if (stored_type_id == type_id) {
                return self.component_storages.items[i].hasComponent(entity.id);
            }
        }
        return false;
    }

    pub fn getAllEntitiesWith(self: *World, comptime T: type, allocator: std.mem.Allocator) !std.ArrayList(Entity) {
        var entities = std.ArrayList(Entity).init(allocator);
        const type_id = getComponentTypeId(T);

        for (self.component_type_ids.items, 0..) |stored_type_id, i| {
            if (stored_type_id == type_id) {
                for (self.component_storages.items[i].index_to_entity.items) |entity_id| {
                    try entities.append(Entity.init(entity_id));
                }
                break;
            }
        }

        return entities;
    }

    // Get all active entities (for GUI inspection)
    pub fn getAllActiveEntities(self: *World, allocator: std.mem.Allocator) !std.ArrayList(Entity) {
        var entities = std.ArrayList(Entity).init(allocator);
        var entity_set = std.AutoHashMap(u32, void).init(allocator);
        defer entity_set.deinit();

        // Collect all entity IDs from component storages
        for (self.component_storages.items) |storage| {
            for (storage.index_to_entity.items) |entity_id| {
                try entity_set.put(entity_id, {});
            }
        }

        // Convert to entity list
        var iterator = entity_set.iterator();
        while (iterator.next()) |entry| {
            try entities.append(Entity.init(entry.key_ptr.*));
        }

        return entities;
    }

    // Get component type name for display
    pub fn getComponentTypeName(self: *World, type_id: u32) []const u8 {
        _ = self;
        // Simple mapping for now - could be extended
        return switch (type_id) {
            0 => "Position",
            1 => "Velocity",
            2 => "Size",
            3 => "Color",
            4 => "Paddle",
            5 => "Ball",
            6 => "Block",
            7 => "Renderable",
            else => "Unknown",
        };
    }
};
