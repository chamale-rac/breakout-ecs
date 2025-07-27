const std = @import("std");

pub const EntityId = u32;
pub const INVALID_ENTITY: EntityId = std.math.maxInt(EntityId);

pub const Entity = struct {
    id: EntityId,

    pub fn init(id: EntityId) Entity {
        return Entity{
            .id = id,
        };
    }

    pub fn isValid(self: Entity) bool {
        return self.id != INVALID_ENTITY;
    }
};
