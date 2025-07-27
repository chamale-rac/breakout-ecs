const std = @import("std");
const raylib = @import("raylib");

pub const Position = struct {
    x: f32,
    y: f32,

    pub fn init(x: f32, y: f32) Position {
        return Position{ .x = x, .y = y };
    }
};

pub const Velocity = struct {
    x: f32,
    y: f32,

    pub fn init(x: f32, y: f32) Velocity {
        return Velocity{ .x = x, .y = y };
    }
};

pub const Size = struct {
    width: f32,
    height: f32,

    pub fn init(width: f32, height: f32) Size {
        return Size{ .width = width, .height = height };
    }
};

pub const Color = struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,

    pub fn init(r: u8, g: u8, b: u8, a: u8) Color {
        return Color{ .r = r, .g = g, .b = b, .a = a };
    }

    pub fn toRaylib(self: Color) raylib.Color {
        return raylib.Color{ .r = self.r, .g = self.g, .b = self.b, .a = self.a };
    }
};

pub const Paddle = struct {
    speed: f32,

    pub fn init(speed: f32) Paddle {
        return Paddle{ .speed = speed };
    }
};

pub const Ball = struct {
    speed: f32,
    max_speed: f32,
    speed_increase: f32,

    pub fn init(speed: f32, max_speed: f32, speed_increase: f32) Ball {
        return Ball{
            .speed = speed,
            .max_speed = max_speed,
            .speed_increase = speed_increase,
        };
    }
};

pub const Block = struct {
    destroyed: bool,

    pub fn init() Block {
        return Block{ .destroyed = false };
    }
};

pub const Rectangle = struct {
    pub fn getBounds(pos: Position, size: Size) raylib.Rectangle {
        return raylib.Rectangle{
            .x = pos.x,
            .y = pos.y,
            .width = size.width,
            .height = size.height,
        };
    }

    pub fn checkCollision(pos1: Position, size1: Size, pos2: Position, size2: Size) bool {
        const rect1 = getBounds(pos1, size1);
        const rect2 = getBounds(pos2, size2);
        return raylib.checkCollisionRecs(rect1, rect2);
    }
};

pub const Renderable = struct {
    visible: bool,

    pub fn init() Renderable {
        return Renderable{ .visible = true };
    }
};
