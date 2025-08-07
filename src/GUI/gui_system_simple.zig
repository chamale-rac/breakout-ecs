const std = @import("std");
const raylib = @import("raylib");
const dvui = @import("dvui");
const RaylibBackend = dvui.backend;
const World = @import("../ECS/system/world.zig").World;
const Entity = @import("../ECS/entity/entity.zig").Entity;
const components = @import("../PONG/components/components.zig");

// Global pause state
pub var game_paused: bool = false;

pub const GuiSystem = struct {
    allocator: std.mem.Allocator,
    world: ?*World = null,
    show_debug_window: bool = false,
    show_entity_window: bool = true,
    show_pause_controls: bool = true,

    pub fn init(allocator: std.mem.Allocator) !GuiSystem {
        return GuiSystem{
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *GuiSystem) void {
        _ = self;
    }

    pub fn setWorld(self: *GuiSystem, world: *World) void {
        self.world = world;
    }

    pub fn render(self: *GuiSystem) !void {
        // Show a simple GUI using raylib's basic drawing for now
        if (self.show_pause_controls) {
            self.renderSimplePauseControls();
        }

        if (self.show_entity_window) {
            self.renderSimpleEntityInfo();
        }
    }

    fn renderSimplePauseControls(self: *GuiSystem) void {
        _ = self;

        // Draw a simple pause control box
        const box_x: i32 = 10;
        const box_y: i32 = 60;
        const box_width: i32 = 200;
        const box_height: i32 = 80;

        raylib.drawRectangle(box_x, box_y, box_width, box_height, raylib.Color{ .r = 0, .g = 0, .b = 0, .a = 180 });
        raylib.drawRectangleLines(box_x, box_y, box_width, box_height, raylib.Color.white);

        const title_text = "Game Controls";
        raylib.drawText(title_text, box_x + 10, box_y + 10, 16, raylib.Color.white);

        const pause_text = if (game_paused) "Game: PAUSED" else "Game: RUNNING";
        const pause_color = if (game_paused) raylib.Color.red else raylib.Color.green;
        raylib.drawText(pause_text, box_x + 10, box_y + 30, 14, pause_color);

        raylib.drawText("SPACE: Toggle Pause", box_x + 10, box_y + 50, 12, raylib.Color.gray);

        // Handle space key for pause toggle
        if (raylib.isKeyPressed(.space)) {
            game_paused = !game_paused;
            std.debug.print("Game {s}\n", .{if (game_paused) "Paused" else "Resumed"});
        }
    }

    fn renderSimpleEntityInfo(self: *GuiSystem) void {
        if (self.world == null) return;

        const box_x: i32 = 220;
        const box_y: i32 = 60;
        const box_width: i32 = 300;
        const box_height: i32 = 150;

        raylib.drawRectangle(box_x, box_y, box_width, box_height, raylib.Color{ .r = 0, .g = 0, .b = 0, .a = 180 });
        raylib.drawRectangleLines(box_x, box_y, box_width, box_height, raylib.Color.white);

        const title_text = "Entity Inspector";
        raylib.drawText(title_text, box_x + 10, box_y + 10, 16, raylib.Color.white);

        const world = self.world.?;

        // Show basic world information
        var buffer: [64:0]u8 = undefined;

        var text = std.fmt.bufPrintZ(&buffer, "Next Entity ID: {d}", .{world.next_entity_id}) catch "Next Entity ID: ?";
        raylib.drawText(text, box_x + 10, box_y + 35, 12, raylib.Color.white);

        text = std.fmt.bufPrintZ(&buffer, "Free Entities: {d}", .{world.free_entities.items.len}) catch "Free Entities: ?";
        raylib.drawText(text, box_x + 10, box_y + 50, 12, raylib.Color.white);

        text = std.fmt.bufPrintZ(&buffer, "Component Types: {d}", .{world.component_type_ids.items.len}) catch "Component Types: ?";
        raylib.drawText(text, box_x + 10, box_y + 65, 12, raylib.Color.white);

        const active_entities = world.next_entity_id - @as(u32, @intCast(world.free_entities.items.len));
        text = std.fmt.bufPrintZ(&buffer, "Active Entities: {d}", .{active_entities}) catch "Active Entities: ?";
        raylib.drawText(text, box_x + 10, box_y + 80, 12, raylib.Color.white);

        raylib.drawText("F1: Toggle Controls", box_x + 10, box_y + 100, 10, raylib.Color.gray);
        raylib.drawText("F2: Toggle Inspector", box_x + 10, box_y + 115, 10, raylib.Color.gray);
        raylib.drawText("F3: Toggle DVUI Demo", box_x + 10, box_y + 130, 10, raylib.Color.gray);
    }
};
