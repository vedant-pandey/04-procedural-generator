const sdl3 = @import("sdl3");
const std = @import("std");

const ScreenWidth = 640;
const ScreenHeight = 480;

const AppState = struct {
    window: sdl3.video.Window,
    renderer: sdl3.render.Renderer,
    screenWidth: usize,
    screenHeight: usize,
    initFlags: sdl3.InitFlags,

    const Self = @This();

    pub fn init(initFlags: sdl3.InitFlags, screenWidth: usize, screenHeight: usize) !*Self {
        try sdl3.init(initFlags);
        const window = try sdl3.video.Window.init("Procedural generation", screenWidth, screenHeight, .{
            .always_on_top = true,
            .mouse_focus = true,
            .input_focus = true,
            .resizable = true,
        });
        window.raise() catch unreachable;

        const renderer = try sdl3.render.Renderer.init(window, null);

        var state = AppState{
            .window = window,
            .renderer = renderer,
            .screenWidth = screenWidth,
            .screenHeight = screenHeight,
            .initFlags = initFlags,
        };

        return &state;
    }

    pub fn deinit(self: *Self) void {
        defer sdl3.shutdown();
        defer sdl3.quit(self.initFlags);
    }
};

pub fn main() !void {
    var state = try AppState.init(.{ .video = true }, ScreenWidth, ScreenHeight);
    defer state.deinit();

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
                else => {},
            }
        }
    }
}
