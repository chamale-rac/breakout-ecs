const std = @import("std");
const raylib = @import("raylib");
const World = @import("../../ECS/system/world.zig").World;
const EntityModule = @import("../../ECS/entity/entity.zig");
const Entity = EntityModule.Entity;
const components = @import("../components/components.zig");
const InputSystem = @import("../systems/input_system.zig").InputSystem;
const MovementSystem = @import("../systems/movement_system.zig").MovementSystem;
const CollisionSystem = @import("../systems/collision_system.zig").CollisionSystem;
const RenderSystem = @import("../systems/render_system.zig").RenderSystem;

pub const PongGame = struct {
    allocator: std.mem.Allocator,
    world: World,
    input_system: InputSystem,
    movement_system: MovementSystem,
    collision_system: CollisionSystem,
    render_system: RenderSystem,
    screen_width: f32,
    screen_height: f32,
    game_over: bool,
    paddle_entity: Entity,
    ball_entity: Entity,
    blocks: std.ArrayList(Entity),

    pub fn init(allocator: std.mem.Allocator, screen_width: f32, screen_height: f32) !PongGame {
        var game = PongGame{
            .allocator = allocator,
            .world = World.init(allocator),
            .input_system = InputSystem.init(screen_width),
            .movement_system = MovementSystem.init(),
            .collision_system = CollisionSystem.init(screen_width, screen_height, undefined), // We'll set this properly below
            .render_system = RenderSystem.init(),
            .screen_width = screen_width,
            .screen_height = screen_height,
            .game_over = false,
            .paddle_entity = Entity.init(EntityModule.INVALID_ENTITY),
            .ball_entity = Entity.init(EntityModule.INVALID_ENTITY),
            .blocks = std.ArrayList(Entity).init(allocator),
        };

        // Fix the game_over pointer
        game.collision_system.game_over = &game.game_over;

        // Set world for all systems
        game.input_system.setWorld(&game.world);
        game.movement_system.setWorld(&game.world);
        game.collision_system.setWorld(&game.world);
        game.render_system.setWorld(&game.world);

        try game.createGameEntities();

        return game;
    }

    pub fn deinit(self: *PongGame) void {
        self.blocks.deinit();
        self.input_system.deinit();
        self.movement_system.deinit();
        self.collision_system.deinit();
        self.render_system.deinit();
        self.world.deinit();
    }

    fn createGameEntities(self: *PongGame) !void {
        // Create paddle
        self.paddle_entity = self.world.createEntity();
        try self.world.addComponent(self.paddle_entity, components.Position, components.Position.init(self.screen_width / 2 - 50, self.screen_height - 50));
        try self.world.addComponent(self.paddle_entity, components.Size, components.Size.init(100, 20));
        try self.world.addComponent(self.paddle_entity, components.Color, components.Color.init(255, 255, 255, 255));
        try self.world.addComponent(self.paddle_entity, components.Paddle, components.Paddle.init(800));
        try self.world.addComponent(self.paddle_entity, components.Renderable, components.Renderable.init());

        // Create ball
        self.ball_entity = self.world.createEntity();
        try self.world.addComponent(self.ball_entity, components.Position, components.Position.init(self.screen_width / 2 - 10, self.screen_height / 2));
        try self.world.addComponent(self.ball_entity, components.Size, components.Size.init(20, 20));
        try self.world.addComponent(self.ball_entity, components.Color, components.Color.init(255, 255, 0, 255));
        try self.world.addComponent(self.ball_entity, components.Velocity, components.Velocity.init(200, 200));
        try self.world.addComponent(self.ball_entity, components.Ball, components.Ball.init(200, 800, 50));
        try self.world.addComponent(self.ball_entity, components.Renderable, components.Renderable.init());

        // Create blocks
        const blocks_per_row = 10;
        const block_rows = 5;
        const block_width = self.screen_width / @as(f32, @floatFromInt(blocks_per_row));
        const block_height = 30;
        const start_y = 80;

        var row: u32 = 0;
        while (row < block_rows) : (row += 1) {
            var col: u32 = 0;
            while (col < blocks_per_row) : (col += 1) {
                const block_entity = self.world.createEntity();
                const x = @as(f32, @floatFromInt(col)) * block_width;
                const y = start_y + @as(f32, @floatFromInt(row)) * block_height;

                // Different colors for different rows
                var color = components.Color.init(255, 0, 0, 255); // Red
                switch (row) {
                    0 => color = components.Color.init(255, 0, 0, 255), // Red
                    1 => color = components.Color.init(255, 165, 0, 255), // Orange
                    2 => color = components.Color.init(255, 255, 0, 255), // Yellow
                    3 => color = components.Color.init(0, 255, 0, 255), // Green
                    4 => color = components.Color.init(0, 0, 255, 255), // Blue
                    else => {},
                }

                try self.world.addComponent(block_entity, components.Position, components.Position.init(x, y));
                try self.world.addComponent(block_entity, components.Size, components.Size.init(block_width - 2, block_height - 2));
                try self.world.addComponent(block_entity, components.Color, color);
                try self.world.addComponent(block_entity, components.Block, components.Block.init());
                try self.world.addComponent(block_entity, components.Renderable, components.Renderable.init());

                try self.blocks.append(block_entity);
            }
        }
    }

    pub fn update(self: *PongGame, delta_time: f32) void {
        if (self.game_over) return;

        // Update systems
        self.input_system.update(delta_time);
        self.movement_system.update(delta_time);
        self.collision_system.update(delta_time);

        // Check if ball fell off bottom of screen
        if (self.world.getComponent(self.ball_entity, components.Position)) |ball_pos| {
            if (ball_pos.y > self.screen_height) {
                self.game_over = true;
                std.debug.print("Game Over! Ball fell off screen!\n", .{});
            }
        }

        // Check if all blocks are destroyed
        var blocks_remaining: u32 = 0;
        for (self.blocks.items) |block_entity| {
            if (self.world.getComponent(block_entity, components.Block)) |block| {
                if (!block.destroyed) {
                    blocks_remaining += 1;
                }
            }
        }

        if (blocks_remaining == 0) {
            std.debug.print("You Win! All blocks destroyed!\n", .{});
            self.game_over = true;
        }
    }

    pub fn render(self: *PongGame) void {
        self.render_system.render();

        // Draw game over message
        if (self.game_over) {
            const message = "Game Over! Press ESC to exit";
            const font_size = 40;
            const text_width = raylib.measureText(message, font_size);
            raylib.drawText(message, @as(i32, @intFromFloat(self.screen_width / 2)) - @divTrunc(text_width, 2), @as(i32, @intFromFloat(self.screen_height / 2)), font_size, raylib.Color.red);
        }
    }

    pub fn isGameOver(self: *PongGame) bool {
        return self.game_over;
    }
};
