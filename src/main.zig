const std = @import("std");
const Game = @import("GAME/game/game.zig").Game;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var game_instance = try Game.init("Breakout Game", 800, 600, allocator);
    defer game_instance.deinit();

    game_instance.run();
}
