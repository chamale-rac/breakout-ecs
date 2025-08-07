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
    show_entity_window: bool = true,
    show_pause_controls: bool = true,
    
    pub fn init(allocator: std.mem.Allocator) !GuiSystem {
        // Don't initialize DVUI here - do it lazily in render()
        return GuiSystem{
            .allocator = allocator,
        };
    }
    
    pub fn deinit(self: *GuiSystem) void {
        _ = self;
        // Cleanup will happen automatically when the application exits
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
        
        // Render GUI content
        try self.renderGUI();
        
        // End DVUI frame
        _ = try dvui_window.?.end(.{});
        
        // Handle cursor for floating windows
        if (dvui_window.?.cursorRequestedFloating()) |cursor| {
            dvui_backend.?.setCursor(cursor);
        }
    }
    
    fn renderGUI(self: *GuiSystem) !void {
        // Render pause controls floating window
        if (self.show_pause_controls) {
            var float = dvui.floatingWindow(@src(), .{}, .{ .min_size_content = .{ .w = 200, .h = 120 } });
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
            _ = dvui.checkbox(@src(), &self.show_entity_window, "Show Entity Inspector", .{});
            _ = dvui.checkbox(@src(), &self.show_debug_window, "Show DVUI Demo", .{});
        }
        
        // Render entity inspector floating window
        if (self.show_entity_window and self.world != null) {
            var float = dvui.floatingWindow(@src(), .{}, .{ .min_size_content = .{ .w = 350, .h = 250 } });
            defer float.deinit();

            _ = dvui.windowHeader("Entity Inspector", "", &self.show_entity_window);

            var scroll = dvui.scrollArea(@src(), .{}, .{ .expand = .both });
            defer scroll.deinit();

            const world = self.world.?;
            
            // Show world statistics
            dvui.label(@src(), "ECS World Statistics", .{}, .{ .font_style = .title_4 });
            _ = dvui.separator(@src(), .{});
            
            dvui.label(@src(), "Next Entity ID: {d}", .{world.next_entity_id}, .{});
            dvui.label(@src(), "Free Entities: {d}", .{world.free_entities.items.len}, .{});
            dvui.label(@src(), "Component Types: {d}", .{world.component_type_ids.items.len}, .{});
            
            const active_entities = world.next_entity_id - @as(u32, @intCast(world.free_entities.items.len));
            dvui.label(@src(), "Active Entities: {d}", .{active_entities}, .{});
            
            _ = dvui.separator(@src(), .{});
            
            // Show component storages info
            dvui.label(@src(), "Component Storages:", .{}, .{ .font_style = .heading });
            
            for (world.component_storages.items, 0..) |storage, i| {
                if (i < world.component_type_ids.items.len) {
                    const type_id = world.component_type_ids.items[i];
                    const entity_count = storage.index_to_entity.items.len;
                    
                    var label_buffer: [64]u8 = undefined;
                    const label_text = std.fmt.bufPrint(&label_buffer, "Component Type {d}", .{type_id}) catch "Component Type";
                    if (dvui.expander(@src(), label_text, .{}, .{ .id_extra = i })) {
                        dvui.label(@src(), "  Entities: {d}", .{entity_count}, .{ .id_extra = i * 10 + 1 });
                        dvui.label(@src(), "  Data Size: {d} bytes", .{storage.component_size}, .{ .id_extra = i * 10 + 2 });
                        dvui.label(@src(), "  Total Storage: {d} bytes", .{storage.component_data.items.len}, .{ .id_extra = i * 10 + 3 });
                    }
                }
            }
        }
        
        // Show DVUI demo window
        if (self.show_debug_window) {
            dvui.Examples.demo();
        }
    }
};