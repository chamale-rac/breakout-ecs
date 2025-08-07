const std = @import("std");
const raylib = @import("raylib");
const dvui = @import("dvui");
const RaylibBackend = dvui.backend;
const World = @import("../ECS/system/world.zig").World;
const Entity = @import("../ECS/entity/entity.zig").Entity;
const components = @import("../PONG/components/components.zig");

// Global pause state
pub var game_paused: bool = false;

// Static DVUI backend and window - initialized once
var dvui_backend: ?RaylibBackend.RaylibBackend = null;
var dvui_window: ?dvui.Window = null;
var dvui_initialized: bool = false;

pub const GuiSystem = struct {
    allocator: std.mem.Allocator,
    world: ?*World = null,
    show_debug_window: bool = false,
    show_entity_window: bool = false,
    show_pause_controls: bool = true,
    show_entity_inspector: bool = false,

    // Entity selection and inspection
    selected_entity: ?Entity = null,
    entities_list: std.ArrayList(Entity),

    // Search functionality
    search_buffer: [64]u8 = [_]u8{0} ** 64,
    search_text_len: usize = 0,

    pub fn init(allocator: std.mem.Allocator) !GuiSystem {
        return GuiSystem{
            .allocator = allocator,
            .entities_list = std.ArrayList(Entity).init(allocator),
        };
    }

    pub fn deinit(self: *GuiSystem) void {
        self.entities_list.deinit();
    }

    pub fn setWorld(self: *GuiSystem, world: *World) void {
        self.world = world;
    }

    pub fn render(self: *GuiSystem) !void {
        // Initialize DVUI lazily on first render call
        if (!dvui_initialized) {
            dvui_backend = RaylibBackend.init(self.allocator);
            dvui_window = try dvui.Window.init(@src(), self.allocator, dvui_backend.?.backend(), .{});
            dvui_initialized = true;
        }

        // Begin DVUI frame
        try dvui_window.?.begin(std.time.nanoTimestamp());

        // Process raylib events through DVUI
        _ = try dvui_backend.?.addAllEvents(&dvui_window.?);

        // Update entities list
        if (self.world != null) {
            self.updateEntitiesList() catch {};
        }

        // Render GUI content
        try self.renderGUI();

        // End DVUI frame
        _ = try dvui_window.?.end(.{});

        // Handle cursor for floating windows
        if (dvui_window.?.cursorRequestedFloating()) |cursor| {
            dvui_backend.?.setCursor(cursor);
        }
    }

    fn updateEntitiesList(self: *GuiSystem) !void {
        if (self.world == null) return;

        // Clear and rebuild entities list
        self.entities_list.clearRetainingCapacity();
        const entities = try self.world.?.getAllActiveEntities(self.allocator);
        defer entities.deinit();

        for (entities.items) |entity| {
            try self.entities_list.append(entity);
        }
    }

    fn renderGUI(self: *GuiSystem) !void {
        // Render pause controls floating window
        if (self.show_pause_controls) {
            // Try to position in top right by using a specific anchor
            var float = dvui.floatingWindow(@src(), .{}, .{
                .min_size_content = .{ .w = 200, .h = 140 },
                .expand = .none, // Don't expand to fill space
            });
            defer float.deinit();

            _ = dvui.windowHeader("Game Controls", "", &self.show_pause_controls);

            // Pause/Resume button
            const button_text = if (game_paused) "Resume Game" else "Pause Game";
            if (dvui.button(@src(), button_text, .{}, .{ .expand = .horizontal })) {
                game_paused = !game_paused;
                std.debug.print("Game {s}\n", .{if (game_paused) "Paused" else "Resumed"});
            }

            // Show current state
            const state_text = if (game_paused) "Status: PAUSED" else "Status: RUNNING";
            const status_color = if (game_paused) dvui.Color{ .r = 255, .g = 0, .b = 0, .a = 255 } else dvui.Color{ .r = 0, .g = 255, .b = 0, .a = 255 };
            dvui.label(@src(), "{s}", .{state_text}, .{ .color_text = .{ .color = status_color } });

            _ = dvui.separator(@src(), .{});

            // Window toggles
            _ = dvui.checkbox(@src(), &self.show_entity_window, "Show Entity List", .{});
            _ = dvui.checkbox(@src(), &self.show_entity_inspector, "Show Entity Inspector", .{});
        }

        // Render entities list window
        if (self.show_entity_window and self.world != null) {
            var float = dvui.floatingWindow(@src(), .{}, .{ .min_size_content = .{ .w = 250, .h = 300 } });
            defer float.deinit();

            _ = dvui.windowHeader("Entity List", "", &self.show_entity_window);

            var scroll = dvui.scrollArea(@src(), .{}, .{ .expand = .both });
            defer scroll.deinit();

            const world = self.world.?;

            dvui.label(@src(), "Active Entities: {d}", .{self.entities_list.items.len}, .{ .font_style = .heading });

            // Search functionality - Use buttons for common searches for now
            dvui.label(@src(), "Quick Search:", .{}, .{});

            if (dvui.button(@src(), "Show All", .{}, .{ .id_extra = 1000 })) {
                self.search_text_len = 0; // Clear search
            }

            if (dvui.button(@src(), "Paddle", .{}, .{ .id_extra = 1001 })) {
                const search_term = "paddle";
                @memcpy(self.search_buffer[0..search_term.len], search_term);
                self.search_text_len = search_term.len;
            }

            if (dvui.button(@src(), "Ball", .{}, .{ .id_extra = 1002 })) {
                const search_term = "ball";
                @memcpy(self.search_buffer[0..search_term.len], search_term);
                self.search_text_len = search_term.len;
            }

            if (dvui.button(@src(), "Block", .{}, .{ .id_extra = 1003 })) {
                const search_term = "block";
                @memcpy(self.search_buffer[0..search_term.len], search_term);
                self.search_text_len = search_term.len;
            }

            if (dvui.button(@src(), "Wall", .{}, .{ .id_extra = 1004 })) {
                const search_term = "wall";
                @memcpy(self.search_buffer[0..search_term.len], search_term);
                self.search_text_len = search_term.len;
            }

            _ = dvui.separator(@src(), .{});

            // Text entry for custom search
            dvui.label(@src(), "Custom Search:", .{}, .{});
            {
                var text_entry = dvui.textEntry(@src(), .{}, .{ .expand = .horizontal, .min_size_content = .{ .w = 200, .h = 25 } });
                defer text_entry.deinit();

                // Get the current text from the text entry
                const current_text = text_entry.getText();
                if (current_text.len != self.search_text_len or !std.mem.eql(u8, current_text, self.search_buffer[0..self.search_text_len])) {
                    // Text has changed, update our search buffer
                    if (current_text.len <= self.search_buffer.len) {
                        @memcpy(self.search_buffer[0..current_text.len], current_text);
                        if (current_text.len < self.search_buffer.len) {
                            self.search_buffer[current_text.len] = 0;
                        }
                        self.search_text_len = current_text.len;
                    }
                }
            }

            // Show current search filter
            if (self.search_text_len > 0) {
                const search_text = self.search_buffer[0..self.search_text_len];
                dvui.label(@src(), "Filtering by: {s}", .{search_text}, .{ .color_text = .{ .color = .{ .r = 0, .g = 255, .b = 0, .a = 255 } } });
            }

            _ = dvui.separator(@src(), .{});

            // List all entities (with filtering)
            for (self.entities_list.items, 0..) |entity, i| {
                var entity_name_buffer: [64]u8 = undefined;
                const entity_name = self.getEntityDisplayName(entity, &entity_name_buffer);

                // Filter by search text if any
                if (self.search_text_len > 0) {
                    const search_text = self.search_buffer[0..self.search_text_len];
                    if (!self.containsIgnoreCase(entity_name, search_text)) {
                        continue; // Skip this entity if it doesn't match search
                    }
                }

                // Check if this entity is selected
                const is_selected = if (self.selected_entity) |selected| selected.id == entity.id else false;

                // Add selection indicator
                if (is_selected) {
                    var selected_buffer: [64]u8 = undefined;
                    const selected_text = std.fmt.bufPrint(&selected_buffer, ">>> {s} <<<", .{entity_name}) catch ">>> Entity <<<";
                    if (dvui.button(@src(), selected_text, .{}, .{ .expand = .horizontal, .id_extra = i })) {
                        self.selected_entity = null; // Deselect if clicked again
                    }
                } else {
                    if (dvui.button(@src(), entity_name, .{}, .{ .expand = .horizontal, .id_extra = i })) {
                        self.selected_entity = entity;
                        std.debug.print("Selected entity {d}\n", .{entity.id});
                    }
                }

                // Show component count for this entity
                var comp_count: u32 = 0;
                for (world.component_storages.items) |*storage| {
                    if (storage.hasComponent(entity.id)) {
                        comp_count += 1;
                    }
                }
                dvui.label(@src(), "  Components: {d}", .{comp_count}, .{ .color_text = .{ .color = .{ .r = 150, .g = 150, .b = 150, .a = 255 } }, .id_extra = i * 100 });
            }
        }

        // Render individual entity inspector
        if (self.show_entity_inspector and self.selected_entity != null and self.world != null) {
            try self.renderEntityInspector();
        }
    }

    fn renderEntityInspector(self: *GuiSystem) !void {
        const entity = self.selected_entity.?;
        const world = self.world.?;

        var float = dvui.floatingWindow(@src(), .{}, .{ .min_size_content = .{ .w = 400, .h = 500 } });
        defer float.deinit();

        var title_buffer: [64]u8 = undefined;
        const title = std.fmt.bufPrint(&title_buffer, "Entity Inspector - Entity {d}", .{entity.id}) catch "Entity Inspector";
        _ = dvui.windowHeader(title, "", &self.show_entity_inspector);

        var scroll = dvui.scrollArea(@src(), .{}, .{ .expand = .both });
        defer scroll.deinit();

        dvui.label(@src(), "Entity ID: {d}", .{entity.id}, .{ .font_style = .title_4 });
        _ = dvui.separator(@src(), .{});

        // Check and edit each component type
        if (world.hasComponent(entity, components.Position)) {
            if (dvui.expander(@src(), "Position", .{}, .{ .id_extra = 1 })) {
                if (world.getComponent(entity, components.Position)) |pos| {
                    dvui.label(@src(), "X: {d:.1}", .{pos.x}, .{});
                    var pos_x_fraction = pos.x / 800.0;
                    if (dvui.slider(@src(), .horizontal, &pos_x_fraction, .{ .id_extra = 11, .min_size_content = .{ .w = 200, .h = 20 } })) {
                        pos.x = pos_x_fraction * 800.0;
                    }

                    dvui.label(@src(), "Y: {d:.1}", .{pos.y}, .{});
                    var pos_y_fraction = pos.y / 600.0;
                    if (dvui.slider(@src(), .horizontal, &pos_y_fraction, .{ .id_extra = 12, .min_size_content = .{ .w = 200, .h = 20 } })) {
                        pos.y = pos_y_fraction * 600.0;
                    }
                }
            }
        }

        if (world.hasComponent(entity, components.Velocity)) {
            if (dvui.expander(@src(), "Velocity", .{}, .{ .id_extra = 2 })) {
                if (world.getComponent(entity, components.Velocity)) |vel| {
                    dvui.label(@src(), "X Velocity: {d:.1}", .{vel.x}, .{});
                    var vel_x_fraction = (vel.x + 500.0) / 1000.0;
                    if (dvui.slider(@src(), .horizontal, &vel_x_fraction, .{ .id_extra = 21, .min_size_content = .{ .w = 200, .h = 20 } })) {
                        vel.x = (vel_x_fraction * 1000.0) - 500.0;
                    }

                    dvui.label(@src(), "Y Velocity: {d:.1}", .{vel.y}, .{});
                    var vel_y_fraction = (vel.y + 500.0) / 1000.0;
                    if (dvui.slider(@src(), .horizontal, &vel_y_fraction, .{ .id_extra = 22, .min_size_content = .{ .w = 200, .h = 20 } })) {
                        vel.y = (vel_y_fraction * 1000.0) - 500.0;
                    }
                }
            }
        }

        if (world.hasComponent(entity, components.Size)) {
            if (dvui.expander(@src(), "Size", .{}, .{ .id_extra = 3 })) {
                if (world.getComponent(entity, components.Size)) |size| {
                    dvui.label(@src(), "Width: {d:.1}", .{size.width}, .{});
                    var width_fraction = (size.width - 1.0) / 199.0;
                    if (dvui.slider(@src(), .horizontal, &width_fraction, .{ .id_extra = 31, .min_size_content = .{ .w = 200, .h = 20 } })) {
                        size.width = (width_fraction * 199.0) + 1.0;
                    }

                    dvui.label(@src(), "Height: {d:.1}", .{size.height}, .{});
                    var height_fraction = (size.height - 1.0) / 199.0;
                    if (dvui.slider(@src(), .horizontal, &height_fraction, .{ .id_extra = 32, .min_size_content = .{ .w = 200, .h = 20 } })) {
                        size.height = (height_fraction * 199.0) + 1.0;
                    }
                }
            }
        }

        if (world.hasComponent(entity, components.Color)) {
            if (dvui.expander(@src(), "Color", .{}, .{ .id_extra = 4 })) {
                if (world.getComponent(entity, components.Color)) |color| {
                    dvui.label(@src(), "Red: {d}", .{color.r}, .{});
                    var red_fraction = @as(f32, @floatFromInt(color.r)) / 255.0;
                    if (dvui.slider(@src(), .horizontal, &red_fraction, .{ .id_extra = 41, .min_size_content = .{ .w = 200, .h = 20 } })) {
                        color.r = @as(u8, @intFromFloat(red_fraction * 255.0));
                    }

                    dvui.label(@src(), "Green: {d}", .{color.g}, .{});
                    var green_fraction = @as(f32, @floatFromInt(color.g)) / 255.0;
                    if (dvui.slider(@src(), .horizontal, &green_fraction, .{ .id_extra = 42, .min_size_content = .{ .w = 200, .h = 20 } })) {
                        color.g = @as(u8, @intFromFloat(green_fraction * 255.0));
                    }

                    dvui.label(@src(), "Blue: {d}", .{color.b}, .{});
                    var blue_fraction = @as(f32, @floatFromInt(color.b)) / 255.0;
                    if (dvui.slider(@src(), .horizontal, &blue_fraction, .{ .id_extra = 43, .min_size_content = .{ .w = 200, .h = 20 } })) {
                        color.b = @as(u8, @intFromFloat(blue_fraction * 255.0));
                    }

                    dvui.label(@src(), "Alpha: {d}", .{color.a}, .{});
                    var alpha_fraction = @as(f32, @floatFromInt(color.a)) / 255.0;
                    if (dvui.slider(@src(), .horizontal, &alpha_fraction, .{ .id_extra = 44, .min_size_content = .{ .w = 200, .h = 20 } })) {
                        color.a = @as(u8, @intFromFloat(alpha_fraction * 255.0));
                    }
                }
            }
        }

        if (world.hasComponent(entity, components.Ball)) {
            if (dvui.expander(@src(), "Ball", .{}, .{ .id_extra = 5 })) {
                if (world.getComponent(entity, components.Ball)) |ball| {
                    dvui.label(@src(), "Speed: {d:.1}", .{ball.speed}, .{});
                    var speed_fraction = ball.speed / 1000.0;
                    if (dvui.slider(@src(), .horizontal, &speed_fraction, .{ .id_extra = 51, .min_size_content = .{ .w = 200, .h = 20 } })) {
                        ball.speed = speed_fraction * 1000.0;
                    }

                    dvui.label(@src(), "Max Speed: {d:.1}", .{ball.max_speed}, .{});
                    var max_speed_fraction = ball.max_speed / 2000.0;
                    if (dvui.slider(@src(), .horizontal, &max_speed_fraction, .{ .id_extra = 52, .min_size_content = .{ .w = 200, .h = 20 } })) {
                        ball.max_speed = max_speed_fraction * 2000.0;
                    }

                    dvui.label(@src(), "Speed Increase: {d:.1}", .{ball.speed_increase}, .{});
                    var speed_inc_fraction = ball.speed_increase / 100.0;
                    if (dvui.slider(@src(), .horizontal, &speed_inc_fraction, .{ .id_extra = 53, .min_size_content = .{ .w = 200, .h = 20 } })) {
                        ball.speed_increase = speed_inc_fraction * 100.0;
                    }
                }
            }
        }

        if (world.hasComponent(entity, components.Paddle)) {
            if (dvui.expander(@src(), "Paddle", .{}, .{ .id_extra = 6 })) {
                if (world.getComponent(entity, components.Paddle)) |paddle| {
                    dvui.label(@src(), "Speed: {d:.1}", .{paddle.speed}, .{});
                    var paddle_speed_fraction = paddle.speed / 1000.0;
                    if (dvui.slider(@src(), .horizontal, &paddle_speed_fraction, .{ .id_extra = 61, .min_size_content = .{ .w = 200, .h = 20 } })) {
                        paddle.speed = paddle_speed_fraction * 1000.0;
                    }
                }
            }
        }

        if (world.hasComponent(entity, components.Block)) {
            if (dvui.expander(@src(), "Block", .{}, .{ .id_extra = 7 })) {
                if (world.getComponent(entity, components.Block)) |block| {
                    _ = dvui.checkbox(@src(), &block.destroyed, "Destroyed", .{ .id_extra = 71 });
                }
            }
        }

        if (world.hasComponent(entity, components.Renderable)) {
            if (dvui.expander(@src(), "Renderable", .{}, .{ .id_extra = 8 })) {
                if (world.getComponent(entity, components.Renderable)) |renderable| {
                    _ = dvui.checkbox(@src(), &renderable.visible, "Visible", .{ .id_extra = 81 });
                }
            }
        }
    }

    fn getEntityDisplayName(self: *GuiSystem, entity: Entity, buffer: []u8) []const u8 {
        if (self.world == null) {
            return std.fmt.bufPrint(buffer, "Entity {d}", .{entity.id}) catch "Entity";
        }

        const world = self.world.?;

        // Check for specific component combinations to determine entity type
        if (world.hasComponent(entity, components.Paddle)) {
            return std.fmt.bufPrint(buffer, "Paddle {d}", .{entity.id}) catch "Paddle";
        }

        if (world.hasComponent(entity, components.Ball)) {
            return std.fmt.bufPrint(buffer, "Ball {d}", .{entity.id}) catch "Ball";
        }

        if (world.hasComponent(entity, components.Block)) {
            return std.fmt.bufPrint(buffer, "Block {d}", .{entity.id}) catch "Block";
        }

        // Check for walls (entities with Position, Size, Color but no specific game components)
        if (world.hasComponent(entity, components.Position) and
            world.hasComponent(entity, components.Size) and
            world.hasComponent(entity, components.Color) and
            !world.hasComponent(entity, components.Paddle) and
            !world.hasComponent(entity, components.Ball) and
            !world.hasComponent(entity, components.Block))
        {
            return std.fmt.bufPrint(buffer, "Wall {d}", .{entity.id}) catch "Wall";
        }

        // Default fallback
        return std.fmt.bufPrint(buffer, "Entity {d}", .{entity.id}) catch "Entity";
    }

    fn containsIgnoreCase(self: *GuiSystem, haystack: []const u8, needle: []const u8) bool {
        _ = self; // Suppress unused parameter warning

        if (needle.len == 0) return true;
        if (haystack.len < needle.len) return false;

        var i: usize = 0;
        while (i <= haystack.len - needle.len) : (i += 1) {
            var match = true;
            for (needle, 0..) |needle_char, j| {
                const haystack_char = haystack[i + j];
                if (std.ascii.toLower(haystack_char) != std.ascii.toLower(needle_char)) {
                    match = false;
                    break;
                }
            }
            if (match) return true;
        }
        return false;
    }
};
