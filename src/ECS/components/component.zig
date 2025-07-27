const std = @import("std");

pub const ComponentTypeId = u32;

var next_component_type_id: ComponentTypeId = 0;

pub fn getComponentTypeId(comptime T: type) ComponentTypeId {
    // Use a simple approach: hash the type name and ensure it's a valid u32
    const type_name = @typeName(T);
    var hash: u32 = 0;
    for (type_name) |c| {
        hash = hash *% 31 +% c;
    }
    // Ensure we don't return 0 or max value
    if (hash == 0) return 1;
    if (hash == std.math.maxInt(u32)) return 2;
    return hash;
}

pub const ComponentStorage = struct {
    allocator: std.mem.Allocator,
    component_data: std.ArrayList(u8),
    entity_to_index: std.AutoHashMap(u32, u32),
    index_to_entity: std.ArrayList(u32),
    component_size: usize,

    pub fn init(allocator: std.mem.Allocator, component_size: usize) ComponentStorage {
        return ComponentStorage{
            .allocator = allocator,
            .component_data = std.ArrayList(u8).init(allocator),
            .entity_to_index = std.AutoHashMap(u32, u32).init(allocator),
            .index_to_entity = std.ArrayList(u32).init(allocator),
            .component_size = component_size,
        };
    }

    pub fn deinit(self: *ComponentStorage) void {
        self.component_data.deinit();
        self.entity_to_index.deinit();
        self.index_to_entity.deinit();
    }

    pub fn addComponent(self: *ComponentStorage, entity_id: u32, component_data: []const u8) !void {
        // Validate component data size
        if (component_data.len != self.component_size) {
            std.debug.print("ComponentStorage size mismatch: expected {}, got {}\n", .{ self.component_size, component_data.len });
            return error.ComponentSizeMismatch;
        }

        const index = self.index_to_entity.items.len;

        // Resize component data array
        const new_size = self.component_data.items.len + self.component_size;
        try self.component_data.resize(new_size);

        // Copy component data
        const dest_start = index * self.component_size;
        @memcpy(self.component_data.items[dest_start .. dest_start + self.component_size], component_data);

        // Update mappings
        try self.entity_to_index.put(entity_id, @intCast(index));
        try self.index_to_entity.append(entity_id);
    }

    pub fn removeComponent(self: *ComponentStorage, entity_id: u32) void {
        if (self.entity_to_index.get(entity_id)) |index| {
            const last_index = self.index_to_entity.items.len - 1;

            if (index != last_index) {
                // Move last component to this position
                const src_start = last_index * self.component_size;
                const dest_start = index * self.component_size;
                @memcpy(self.component_data.items[dest_start .. dest_start + self.component_size], self.component_data.items[src_start .. src_start + self.component_size]);

                // Update mapping for moved entity
                const moved_entity = self.index_to_entity.items[last_index];
                self.entity_to_index.put(moved_entity, @intCast(index)) catch unreachable;
                self.index_to_entity.items[index] = moved_entity;
            }

            // Remove from mappings
            _ = self.entity_to_index.remove(entity_id);
            _ = self.index_to_entity.pop();

            // Resize data array
            const new_size = self.component_data.items.len - self.component_size;
            self.component_data.resize(new_size) catch unreachable;
        }
    }

    pub fn getComponent(self: *ComponentStorage, entity_id: u32) ?[]u8 {
        if (self.entity_to_index.get(entity_id)) |index| {
            const start = index * self.component_size;
            return self.component_data.items[start .. start + self.component_size];
        }
        return null;
    }

    pub fn hasComponent(self: *ComponentStorage, entity_id: u32) bool {
        return self.entity_to_index.contains(entity_id);
    }
};
