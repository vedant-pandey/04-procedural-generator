const sdl3 = @import("sdl3");
const std = @import("std");

const ScreenWidth = 640;
const ScreenHeight = 480;

pub fn main() !void {
    defer sdl3.shutdown();

    const init_flags = sdl3.InitFlags{ .video = true };
    try sdl3.init(init_flags);
    defer sdl3.quit(init_flags);

    const window = try sdl3.video.Window.init("Procedural generation", ScreenWidth, ScreenHeight, .{
        .always_on_top = true,
        .mouse_focus = true,
        .input_focus = true,
        .resizable = true,
    });
    defer window.deinit();

    window.raise() catch unreachable;

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
