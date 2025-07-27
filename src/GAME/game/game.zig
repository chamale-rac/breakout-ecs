const std = @import("std");
const raylib = @import("raylib");
const PongGame = @import("../../PONG/pong/pong.zig").PongGame;

pub const Game = struct {
    screen_width: i32,
    screen_height: i32,
    is_running: bool,
    frame_count: u32,
    delta_time: f32,
    fps: f32,
    pong_game: PongGame,
    fps_buffer: [32]u8,
    allocator: std.mem.Allocator,

    pub fn init(title: [:0]const u8, width: i32, height: i32, allocator: std.mem.Allocator) !Game {
        raylib.initWindow(width, height, title);
        raylib.setTargetFPS(60);
        std.debug.print("Breakout Game Start!\n", .{});

        const pong_game = try PongGame.init(allocator, @floatFromInt(width), @floatFromInt(height));

        return Game{
            .screen_width = width,
            .screen_height = height,
            .is_running = true,
            .frame_count = 0,
            .delta_time = 0.0,
            .fps = 0.0,
            .pong_game = pong_game,
            .fps_buffer = undefined,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Game) void {
        self.pong_game.deinit();
        self.clean();
    }

    pub fn setup(self: *Game) void {
        _ = self;
        // Game setup already done in init
    }

    pub fn frameStart(self: *Game) void {
        self.delta_time = raylib.getFrameTime(); // seconds
    }

    pub fn frameEnd(self: *Game) void {
        self.frame_count += 1;
        self.fps = @as(f32, @floatFromInt(raylib.getFPS()));
    }

    pub fn handleEvents(self: *Game) void {
        if (raylib.windowShouldClose() or raylib.isKeyPressed(.escape)) {
            self.is_running = false;
        }
    }

    pub fn update(self: *Game) void {
        self.pong_game.update(self.delta_time);

        if (self.pong_game.isGameOver()) {
            // Allow ESC to exit even after game over
            if (raylib.isKeyPressed(.escape)) {
                self.is_running = false;
            }
        }
    }

    pub fn render(self: *Game) void {
        raylib.beginDrawing();
        raylib.clearBackground(raylib.Color.black);

        self.pong_game.render();

        const fps_text = std.fmt.bufPrint(&self.fps_buffer, "FPS: {d:.2}", .{self.fps}) catch "FPS: 0.00";
        // Ensure null termination
        if (fps_text.len < self.fps_buffer.len) {
            self.fps_buffer[fps_text.len] = 0;
        }
        raylib.drawText(fps_text.ptr[0..fps_text.len :0], 10, 10, 20, raylib.Color.dark_gray);

        raylib.endDrawing();
    }

    pub fn clean(self: *Game) void {
        _ = self;
        if (!raylib.windowShouldClose()) {
            raylib.closeWindow();
        }
        std.debug.print("Game Over.\n", .{});
    }

    pub fn running(self: *Game) bool {
        return self.is_running;
    }

    pub fn run(self: *Game) void {
        self.setup();

        while (self.running()) {
            self.frameStart();
            self.handleEvents();
            self.update();
            self.render();
            self.frameEnd();
        }

        self.clean();
    }
};
