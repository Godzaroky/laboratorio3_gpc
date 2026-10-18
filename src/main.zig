const std = @import("std");
const rl = @import("raylib");
const bary = @import("barycentric.zig");

const screen_width = 800;
const screen_height = 450;
const grab_radius: f32 = 14;

const presets = [_]bary.Triangle{
    .{ .a = .{ .x = 20, .y = 430 }, .b = .{ .x = 400, .y = 20 }, .c = .{ .x = 780, .y = 430 } },
    .{ .a = .{ .x = 200, .y = 430 }, .b = .{ .x = 400, .y = 20 }, .c = .{ .x = 780, .y = 430 } },
    .{ .a = .{ .x = 20, .y = 20 }, .b = .{ .x = 400, .y = 430 }, .c = .{ .x = 170, .y = 20 } },
};

fn vertex(t: *bary.Triangle, index: usize) *bary.Vec2 {
    return switch (index) {
        0 => &t.a,
        1 => &t.b,
        else => &t.c,
    };
}

fn closestVertex(t: *bary.Triangle, mouse: bary.Vec2) ?usize {
    var best: ?usize = null;
    var best_dist: f32 = grab_radius;
    for (0..3) |i| {
        const v = vertex(t, i);
        const dist = std.math.hypot(v.x - mouse.x, v.y - mouse.y);
        if (dist <= best_dist) {
            best = i;
            best_dist = dist;
        }
    }
    return best;
}

pub fn main() !void {
    rl.initWindow(screen_width, screen_height, "Coordenadas baricentricas");
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    var pixels: [screen_width * screen_height]bary.Color = undefined;

    const image = rl.genImageColor(screen_width, screen_height, .black);
    const texture = try rl.loadTextureFromImage(image);
    rl.unloadImage(image);
    defer rl.unloadTexture(texture);

    var triangle = presets[0];
    var dragging: ?usize = null;
    var dirty = true;

    while (!rl.windowShouldClose()) {
        const keys = [_]rl.KeyboardKey{ .one, .two, .three };
        for (keys, 0..) |key, i| {
            if (rl.isKeyPressed(key)) {
                triangle = presets[i];
                dirty = true;
            }
        }

        const mouse_rl = rl.getMousePosition();
        const mouse = bary.Vec2{ .x = mouse_rl.x, .y = mouse_rl.y };

        if (rl.isMouseButtonPressed(.left)) dragging = closestVertex(&triangle, mouse);
        if (rl.isMouseButtonReleased(.left)) dragging = null;
        if (dragging) |i| {
            const v = vertex(&triangle, i);
            v.x = std.math.clamp(mouse.x, 0, screen_width - 1);
            v.y = std.math.clamp(mouse.y, 0, screen_height - 1);
            dirty = true;
        }

        if (dirty) {
            bary.rasterize(&pixels, screen_width, screen_height, triangle);
            rl.updateTexture(texture, &pixels);
            dirty = false;
        }

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.black);
        rl.drawTexture(texture, 0, 0, .white);

        if (closestVertex(&triangle, mouse) != null or dragging != null) {
            for (0..3) |i| {
                const v = vertex(&triangle, i);
                rl.drawCircleLines(@intFromFloat(v.x), @intFromFloat(v.y), 6, .white);
            }
        }

        const help = "1-3: cambiar | mouse: mover vertices";
        rl.drawText(help, screen_width - rl.measureText(help, 16) - 10, 10, 16, .gray);
    }
}
