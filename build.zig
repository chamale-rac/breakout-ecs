const std = @import("std");

const targets: []const std.Target.Query = &.{
    .{ .cpu_arch = .x86_64, .os_tag = .windows },
};

pub fn build(b: *std.Build) !void {
    for (targets) |t| {
        const target = b.resolveTargetQuery(t);
        const optimize = .ReleaseSafe;

        const exe = b.addExecutable(.{
            .name = "breakout_entt",
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        });

        // Add raylib-zig dependency
        const raylib_dep = b.dependency("raylib_zig", .{
            .target = target,
            .optimize = optimize,
        });

        const raylib = raylib_dep.module("raylib"); // main raylib module
        const raygui = raylib_dep.module("raygui"); // raygui module

        // Add DVUI dependency
        const dvui_dep = b.dependency("dvui", .{
            .target = target,
            .optimize = optimize,
            .backend = .raylib,
        });

        // Add ECS module (own implementation)
        const ecs_module = b.addModule("ecs", .{
            .root_source_file = b.path("src/ECS/ecs.zig"),
        });

        // Add PONG components module
        const pong_components_module = b.addModule("pong_components", .{
            .root_source_file = b.path("src/PONG/components/components.zig"),
            .imports = &.{
                .{ .name = "raylib", .module = raylib },
            },
        });

        // Add PONG systems module
        const pong_systems_module = b.addModule("pong_systems", .{
            .root_source_file = b.path("src/PONG/systems/systems.zig"),
            .imports = &.{
                .{ .name = "raylib", .module = raylib },
                .{ .name = "ecs", .module = ecs_module },
                .{ .name = "pong_components", .module = pong_components_module },
            },
        });

        // Add PONG module
        const pong_module = b.addModule("pong", .{
            .root_source_file = b.path("src/PONG/pong/pong.zig"),
            .imports = &.{
                .{ .name = "raylib", .module = raylib },
                .{ .name = "ecs", .module = ecs_module },
                .{ .name = "pong_components", .module = pong_components_module },
                .{ .name = "pong_systems", .module = pong_systems_module },
            },
        });

        // Add SCENE module
        const scene_module = b.addModule("scene", .{
            .root_source_file = b.path("src/SCENE/scene/scene.zig"),
        });

        // Add GUI module
        const gui_module = b.addModule("gui", .{
            .root_source_file = b.path("src/GUI/gui_system.zig"),
            .imports = &.{
                .{ .name = "raylib", .module = raylib },
                .{ .name = "dvui", .module = dvui_dep.module("dvui_raylib") },
                .{ .name = "ecs", .module = ecs_module },
                .{ .name = "pong_components", .module = pong_components_module },
            },
        });

        // Add GAME module
        const game_module = b.addModule("game", .{
            .root_source_file = b.path("src/GAME/game/game.zig"),
            .imports = &.{
                .{ .name = "raylib", .module = raylib },
                .{ .name = "pong", .module = pong_module },
                .{ .name = "gui", .module = gui_module },
            },
        });

        const raylib_artifact = raylib_dep.artifact("raylib"); // raylib C library

        // Add modules to the executable
        exe.root_module.addImport("raylib", raylib);
        exe.root_module.addImport("raygui", raygui);
        exe.root_module.addImport("dvui", dvui_dep.module("dvui_raylib"));
        exe.root_module.addImport("ecs", ecs_module);
        exe.root_module.addImport("pong_components", pong_components_module);
        exe.root_module.addImport("pong_systems", pong_systems_module);
        exe.root_module.addImport("pong", pong_module);
        exe.root_module.addImport("scene", scene_module);
        exe.root_module.addImport("gui", gui_module);
        exe.root_module.addImport("game", game_module);

        // Link the raylib C library
        exe.linkLibrary(raylib_artifact);

        const target_output = b.addInstallArtifact(exe, .{
            .dest_dir = .{
                .override = .{
                    .custom = try t.zigTriple(b.allocator),
                },
            },
        });

        b.getInstallStep().dependOn(&target_output.step);

        // Create run step
        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());

        if (b.args) |args| {
            run_cmd.addArgs(args);
        }

        const run_step = b.step("run", "Run the app");
        run_step.dependOn(&run_cmd.step);

        // Create test step
        const unit_tests = b.addTest(.{
            .root_module = exe.root_module,
        });

        const run_unit_tests = b.addRunArtifact(unit_tests);

        const test_step = b.step("test", "Run unit tests");
        test_step.dependOn(&run_unit_tests.step);
    }
}
