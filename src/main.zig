const sdl3 = @import("sdl3");
const std = @import("std");

const ScreenWidth = 640;
const ScreenHeight = 480;

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

    const gridSide = 10;

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
                        else => {},
                    }
                },
                .window_resized => {
                    state.height = @intCast(event.window_resized.height);
                    state.width = @intCast(event.window_resized.width);
                },
                else => {},
            }
        }

        try state.renderer.setDrawColor(.{ .r = 0, .g = 0, .b = 0, .a = 255 });
        try state.renderer.clear();
        try state.renderer.setDrawColor(.{ .r = 255, .g = 0, .b = 0, .a = 255 });
        for (0..@divTrunc(state.width, gridSide)) |x| {
            for (0..@divTrunc(state.height, gridSide)) |y| {
                const r: u8 = @intCast((x * 5) % 255);
                const g: u8 = @intCast((y * 5) % 255);
                const b: u8 = @intCast((y * x * 5) % 255);

                try state.renderer.setDrawColor(sdl3.pixels.Color{ .r = r, .g = g, .b = b, .a = 255 });
                const rect = sdl3.rect.FRect{
                    .x = @floatFromInt(x * gridSide),
                    .y = @floatFromInt(y * gridSide),
                    .w = gridSide - 1,
                    .h = gridSide - 1,
                };
                try state.renderer.renderFillRect(rect);
            }
        }

        try state.renderer.present();
    }
}
