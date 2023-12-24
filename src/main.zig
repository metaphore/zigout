const c = @cImport({
    @cInclude("SDL2/SDL.h");
});
const assert = @import("std").debug.assert;
const math = @import("zlm");

const WINDOW_WIDTH = 800;
const WINDOW_HEIGHT = 640;
const PROJ_SIZE = 96;
const PROJ_SPEED: f32 = 480.0;
const DELTA_TIME: f32 = 1.0 / 60.0;
const DELTA_TIME_INT: i32 = @intFromFloat(DELTA_TIME * 1000.0);

pub fn main() !void {
    if (c.SDL_Init(c.SDL_INIT_VIDEO) != 0) {
        c.SDL_Log("Unable to initialize SDL: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    }
    defer c.SDL_Quit();

    const window = c.SDL_CreateWindow("My Game Window", c.SDL_WINDOWPOS_UNDEFINED, c.SDL_WINDOWPOS_UNDEFINED, WINDOW_WIDTH, WINDOW_HEIGHT, c.SDL_WINDOW_OPENGL) orelse {
        c.SDL_Log("Unable to create window: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    };
    defer c.SDL_DestroyWindow(window);

    const renderer = c.SDL_CreateRenderer(window, -1, c.SDL_RENDERER_ACCELERATED) orelse {
        c.SDL_Log("Unable to create renderer: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    };
    defer c.SDL_DestroyRenderer(renderer);

    var x: f32 = 32.0;
    var y: f32 = 32.0;
    var xDir: f32 = 1.0;
    var yDir: f32 = 1.0;

    var quit = false;
    while (!quit) {
        var event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&event) != 0) {
            switch (event.type) {
                c.SDL_QUIT => {
                    quit = true;
                },
                else => {},
            }
        }

        if (x <= 0) {
            xDir = 1;
        } else if (x + PROJ_SIZE >= WINDOW_WIDTH) {
            xDir = -1;
        }
        if (y <= 0) {
            yDir = 1;
        } else if (y + PROJ_SIZE >= WINDOW_HEIGHT) {
            yDir = -1;
        }

        x += DELTA_TIME * PROJ_SPEED * xDir;
        y += DELTA_TIME * PROJ_SPEED * yDir;

        _ = c.SDL_SetRenderDrawColor(renderer, 0x20, 0x20, 0x40, 0xff);
        _ = c.SDL_RenderClear(renderer);

        const rect = c.SDL_Rect{
            .x = @intFromFloat(x),
            .y = @intFromFloat(y),
            .w = PROJ_SIZE,
            .h = PROJ_SIZE,
        };
        _ = c.SDL_SetRenderDrawColor(renderer, 0xff, 0x20, 0x40, 0xff);
        _ = c.SDL_RenderFillRect(renderer, &rect);

        c.SDL_RenderPresent(renderer);

        c.SDL_Delay(DELTA_TIME_INT);
    }
}
