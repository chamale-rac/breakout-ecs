const std = @import("std");
const raylib = @import("raylib");
const System = @import("../../ECS/system/system.zig").System;
const World = @import("../../ECS/system/world.zig").World;
const EntityModule = @import("../../ECS/entity/entity.zig");
const Entity = EntityModule.Entity;
const components = @import("../components/components.zig");

pub const CollisionSystem = struct {
    base: System,
    screen_width: f32,
    screen_height: f32,
    game_over: *bool,

    pub fn init(screen_width: f32, screen_height: f32, game_over: *bool) CollisionSystem {
        return CollisionSystem{
            .base = System.init(),
            .screen_width = screen_width,
            .screen_height = screen_height,
            .game_over = game_over,
        };
    }

    pub fn deinit(self: *CollisionSystem) void {
        self.base.deinit();
    }

    pub fn setWorld(self: *CollisionSystem, world: *World) void {
        self.base.setWorld(world);
    }

    pub fn update(self: *CollisionSystem, delta_time: f32) void {
        _ = delta_time;
        if (self.base.world == null) return;

        const world = self.base.world.?;
        const allocator = std.heap.page_allocator;

        // Get all ball entities
        var ball_entities = world.getAllEntitiesWith(components.Ball, allocator) catch return;
        defer ball_entities.deinit();

        for (ball_entities.items) |ball_entity| {
            if (world.getComponent(ball_entity, components.Position)) |ball_pos| {
                if (world.getComponent(ball_entity, components.Velocity)) |ball_vel| {
                    if (world.getComponent(ball_entity, components.Size)) |ball_size| {
                        if (world.getComponent(ball_entity, components.Ball)) |ball| {
                            // Wall collision
                            self.checkWallCollision(ball_pos, ball_vel, ball_size, ball);

                            // Paddle collision
                            self.checkPaddleCollision(world, ball_entity, ball_pos, ball_vel, ball_size, ball, allocator);

                            // Block collision
                            self.checkBlockCollision(world, ball_entity, ball_pos, ball_vel, ball_size, ball, allocator);
                        }
                    }
                }
            }
        }
    }

    fn checkWallCollision(self: *CollisionSystem, ball_pos: *components.Position, ball_vel: *components.Velocity, ball_size: *components.Size, ball: *components.Ball) void {
        // Left and right walls - bounce and increase speed
        if (ball_pos.x <= 0) {
            ball_pos.x = 0;
            ball_vel.x = -ball_vel.x;
            self.increaseBallSpeed(ball_vel, ball);
        } else if (ball_pos.x + ball_size.width >= self.screen_width) {
            ball_pos.x = self.screen_width - ball_size.width;
            ball_vel.x = -ball_vel.x;
            self.increaseBallSpeed(ball_vel, ball);
        }

        // Top wall - bounce and increase speed
        if (ball_pos.y <= 0) {
            ball_pos.y = 0;
            ball_vel.y = -ball_vel.y;
            self.increaseBallSpeed(ball_vel, ball);
        }

        // Bottom wall - let ball fall through for game over detection
        // We'll handle this in the main game loop
    }

    fn checkPaddleCollision(self: *CollisionSystem, world: *World, ball_entity: Entity, ball_pos: *components.Position, ball_vel: *components.Velocity, ball_size: *components.Size, ball: *components.Ball, allocator: std.mem.Allocator) void {
        _ = ball_entity;

        // Get all paddle entities
        var paddle_entities = world.getAllEntitiesWith(components.Paddle, allocator) catch return;
        defer paddle_entities.deinit();

        for (paddle_entities.items) |paddle_entity| {
            if (world.getComponent(paddle_entity, components.Position)) |paddle_pos| {
                if (world.getComponent(paddle_entity, components.Size)) |paddle_size| {
                    if (components.Rectangle.checkCollision(ball_pos.*, ball_size.*, paddle_pos.*, paddle_size.*)) {
                        // Only reverse if ball is moving downward
                        if (ball_vel.y > 0) {
                            ball_vel.y = -ball_vel.y;
                            self.increaseBallSpeed(ball_vel, ball);

                            // Move ball above paddle to prevent sticking
                            ball_pos.y = paddle_pos.y - ball_size.height;
                        }
                    }
                }
            }
        }
    }

    fn checkBlockCollision(self: *CollisionSystem, world: *World, ball_entity: Entity, ball_pos: *components.Position, ball_vel: *components.Velocity, ball_size: *components.Size, ball: *components.Ball, allocator: std.mem.Allocator) void {
        _ = ball_entity;

        // Get all block entities
        var block_entities = world.getAllEntitiesWith(components.Block, allocator) catch return;
        defer block_entities.deinit();

        for (block_entities.items) |block_entity| {
            if (world.getComponent(block_entity, components.Block)) |block| {
                if (!block.destroyed) {
                    if (world.getComponent(block_entity, components.Position)) |block_pos| {
                        if (world.getComponent(block_entity, components.Size)) |block_size| {
                            if (components.Rectangle.checkCollision(ball_pos.*, ball_size.*, block_pos.*, block_size.*)) {
                                // Destroy the block
                                block.destroyed = true;

                                // Determine collision side and reverse appropriate velocity
                                const ball_center_x = ball_pos.x + ball_size.width / 2;
                                const ball_center_y = ball_pos.y + ball_size.height / 2;
                                const block_center_x = block_pos.x + block_size.width / 2;
                                const block_center_y = block_pos.y + block_size.height / 2;

                                const dx = ball_center_x - block_center_x;
                                const dy = ball_center_y - block_center_y;

                                if (@abs(dx) > @abs(dy)) {
                                    // Horizontal collision
                                    ball_vel.x = -ball_vel.x;
                                } else {
                                    // Vertical collision
                                    ball_vel.y = -ball_vel.y;
                                }

                                self.increaseBallSpeed(ball_vel, ball);
                                break; // Only handle one collision per frame
                            }
                        }
                    }
                }
            }
        }
    }

    fn increaseBallSpeed(self: *CollisionSystem, ball_vel: *components.Velocity, ball: *components.Ball) void {
        _ = self;
        const current_speed = @sqrt(ball_vel.x * ball_vel.x + ball_vel.y * ball_vel.y);
        const new_speed = @min(current_speed + ball.speed_increase, ball.max_speed);

        if (current_speed > 0) {
            const scale = new_speed / current_speed;
            ball_vel.x *= scale;
            ball_vel.y *= scale;
        }
    }
};
