const std = @import("std");

pub const Vec2 = struct {
    x: f32,
    y: f32,
};

pub const Color = extern struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,
};

pub const Triangle = struct {
    a: Vec2,
    b: Vec2,
    c: Vec2,
};

pub const Weights = struct {
    u: f32,
    v: f32,
    w: f32,
};

pub fn signedArea(p0: Vec2, p1: Vec2, p2: Vec2) f32 {
    return ((p1.x - p0.x) * (p2.y - p0.y) - (p2.x - p0.x) * (p1.y - p0.y)) / 2.0;
}

pub fn weights(t: Triangle, p: Vec2) ?Weights {
    const total = signedArea(t.a, t.b, t.c);
    if (@abs(total) < 1e-6) return null;

    return .{
        .u = signedArea(p, t.b, t.c) / total,
        .v = signedArea(t.a, p, t.c) / total,
        .w = signedArea(t.a, t.b, p) / total,
    };
}

pub fn isInside(bw: Weights) bool {
    const eps: f32 = -1e-5;
    return bw.u >= eps and bw.v >= eps and bw.w >= eps;
}

fn toChannel(value: f32) u8 {
    return @intFromFloat(std.math.clamp(value, 0.0, 1.0) * 255.0 + 0.5);
}

pub fn shade(bw: Weights) Color {
    return .{
        .r = toChannel(bw.u),
        .g = toChannel(bw.v),
        .b = toChannel(bw.w),
        .a = 255,
    };
}

pub fn rasterize(buffer: []Color, width: usize, height: usize, t: Triangle) void {
    @memset(buffer, .{ .r = 0, .g = 0, .b = 0, .a = 255 });
    if (@abs(signedArea(t.a, t.b, t.c)) < 1e-6) return;

    const min_x = @max(@floor(@min(t.a.x, t.b.x, t.c.x)), 0);
    const max_x = @min(@ceil(@max(t.a.x, t.b.x, t.c.x)), @as(f32, @floatFromInt(width - 1)));
    const min_y = @max(@floor(@min(t.a.y, t.b.y, t.c.y)), 0);
    const max_y = @min(@ceil(@max(t.a.y, t.b.y, t.c.y)), @as(f32, @floatFromInt(height - 1)));
    if (min_x > max_x or min_y > max_y) return;

    var y: usize = @intFromFloat(min_y);
    while (y <= @as(usize, @intFromFloat(max_y))) : (y += 1) {
        var x: usize = @intFromFloat(min_x);
        while (x <= @as(usize, @intFromFloat(max_x))) : (x += 1) {
            const p = Vec2{
                .x = @as(f32, @floatFromInt(x)) + 0.5,
                .y = @as(f32, @floatFromInt(y)) + 0.5,
            };
            const bw = weights(t, p).?;
            if (isInside(bw)) buffer[y * width + x] = shade(bw);
        }
    }
}

test "vertex get pure colors" {
    const t = Triangle{
        .a = .{ .x = 0, .y = 100 },
        .b = .{ .x = 50, .y = 0 },
        .c = .{ .x = 100, .y = 100 },
    };
    const at_a = weights(t, t.a).?;
    const at_b = weights(t, t.b).?;
    const at_c = weights(t, t.c).?;
    try std.testing.expectApproxEqAbs(@as(f32, 1), at_a.u, 1e-6);
    try std.testing.expectApproxEqAbs(@as(f32, 1), at_b.v, 1e-6);
    try std.testing.expectApproxEqAbs(@as(f32, 1), at_c.w, 1e-6);
}

test "weights sum to one and centroid is balanced" {
    const t = Triangle{
        .a = .{ .x = 10, .y = 10 },
        .b = .{ .x = 380, .y = 410 },
        .c = .{ .x = 160, .y = 10 },
    };
    const centroid = Vec2{
        .x = (t.a.x + t.b.x + t.c.x) / 3.0,
        .y = (t.a.y + t.b.y + t.c.y) / 3.0,
    };
    const bw = weights(t, centroid).?;
    try std.testing.expectApproxEqAbs(@as(f32, 1), bw.u + bw.v + bw.w, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, 1.0 / 3.0), bw.u, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, 1.0 / 3.0), bw.v, 1e-5);
}

test "points outside are rejected" {
    const t = Triangle{
        .a = .{ .x = 0, .y = 100 },
        .b = .{ .x = 50, .y = 0 },
        .c = .{ .x = 100, .y = 100 },
    };
    try std.testing.expect(!isInside(weights(t, .{ .x = 0, .y = 0 }).?));
    try std.testing.expect(isInside(weights(t, .{ .x = 50, .y = 60 }).?));
}
