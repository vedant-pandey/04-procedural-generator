const sdl3 = @import("sdl3");
const std = @import("std");
const znoise = @import("znoise");

const ScreenWidth = 1383;
const ScreenHeight = 1377;

const AppState = struct {
    window: sdl3.video.Window,
    renderer: sdl3.render.Renderer,
    width: usize,
    height: usize,
    initFlags: sdl3.InitFlags,

    const Self = @This();

    pub fn init(initFlags: sdl3.InitFlags, width: usize, height: usize) !Self {
        try sdl3.init(initFlags);
        const window = try sdl3.video.Window.init("Procedural generation", width, height, .{
            .always_on_top = true,
            .mouse_focus = true,
            .input_focus = true,
            .resizable = true,
        });
        window.raise() catch unreachable;
        try window.setPosition(.{ .absolute = 0 }, .{ .absolute = 0 });

        const renderer = try sdl3.render.Renderer.init(window, null);

        const state = AppState{
            .window = window,
            .renderer = renderer,
            .width = width,
            .height = height,
            .initFlags = initFlags,
        };

        return state;
    }

    pub fn deinit(self: *Self) void {
        defer sdl3.shutdown();
        defer sdl3.quit(self.initFlags);
    }
};

pub fn main() !void {
    var state = try AppState.init(.{ .video = true }, ScreenWidth, ScreenHeight);
    defer state.deinit();

    const seed = 123456;

    var prng = std.Random.DefaultPrng.init(seed);
    const random = prng.random();

    const gridSide = 10;
    var gen = znoise.FnlGenerator{
        .seed = random.int(i32),
        .frequency = 0.005,
        .noise_type = .perlin,
        .rotation_type3 = .none,
        .fractal_type = .fbm,
        .octaves = 3,
        .lacunarity = 2.0,
        .gain = 0.5,
        .weighted_strength = 0.0,
        .ping_pong_strength = 2.0,
        .cellular_distance_func = .euclideansq,
        .cellular_return_type = .distance,
        .cellular_jitter_mod = 1.0,
        .domain_warp_type = .opensimplex2,
        .domain_warp_amp = 1.0,
    };

    var zoom: f32 = 1.0;

    var quit = false;
    while (!quit) {
        while (sdl3.events.poll()) |event| {
            switch (event) {
                .quit => quit = true,
                .terminating => quit = true,
                .key_down => {
                    switch (event.key_down.key.?) {
                        .q => {
                            quit = true;
                        },
                        .r => {
                            gen.seed = random.int(i32);
                        },
                        else => {},
                    }
                },
                .window_resized => {
                    state.height = @intCast(event.window_resized.height);
                    state.width = @intCast(event.window_resized.width);
                    std.debug.print("{} {} \n", .{ state.height, state.width });
                },
                .mouse_wheel => {
                    if (event.mouse_wheel.scroll_y > 0) {
                        zoom += 0.1;
                    } else if (event.mouse_wheel.scroll_y < 0) {
                        zoom -= 0.1;
                    }

                    // Safety clamp
                    zoom = std.math.clamp(zoom, 0.5, 5.0);
                },
                else => {},
            }
        }

        try state.renderer.setDrawColor(.{ .r = 0, .g = 0, .b = 0, .a = 255 });
        try state.renderer.clear();
        try state.renderer.setDrawColor(.{ .r = 255, .g = 0, .b = 0, .a = 255 });
        for (0..@divTrunc(state.width, gridSide)) |x| {
            for (0..@divTrunc(state.height, gridSide)) |y| {
                const raw_noise = gen.noise2(@as(f32, @floatFromInt(x)) * zoom, @as(f32, @floatFromInt(y)) * zoom);
                const height = (raw_noise + 1.0) * 0.5;

                const deepWater = sdl3.pixels.Color{ .r = 0, .g = 0, .b = 128, .a = 255 };
                const water = sdl3.pixels.Color{ .r = 0, .g = 120, .b = 255, .a = 255 };
                const sand = sdl3.pixels.Color{ .r = 240, .g = 240, .b = 100, .a = 255 };
                const grass = sdl3.pixels.Color{ .r = 30, .g = 160, .b = 30, .a = 255 };
                const mountain = sdl3.pixels.Color{ .r = 139, .g = 69, .b = 19, .a = 255 };
                const snow = sdl3.pixels.Color{ .r = 255, .g = 255, .b = 255, .a = 255 };

                var col: sdl3.pixels.Color = undefined;

                if (height < 0.40) {
                    col = deepWater;
                } else if (height < 0.45) {
                    col = water;
                } else if (height < 0.50) {
                    col = sand;
                } else if (height < 0.60) {
                    col = grass;
                } else if (height < 0.65) {
                    col = mountain;
                } else {
                    col = snow;
                }
                try state.renderer.setDrawColor(col);
                const rect = sdl3.rect.FRect{
                    .x = @floatFromInt(x * gridSide),
                    .y = @floatFromInt(y * gridSide),
                    .w = gridSide,
                    .h = gridSide,
                };
                try state.renderer.renderFillRect(rect);
            }
        }

        try state.renderer.present();
    }
}
