const c = @cImport({
    @cInclude("SDL2/SDL.h");
});
const log = @import("std").log;
const assert = @import("std").debug.assert;
const math = @import("zlm/zlm.zig");

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

    var proj_pos = math.Vec2{
        .x = 32.0,
        .y = 32.0,
    };
    var proj_dir = math.Vec2{
        .x = 1.0,
        .y = 0.0,
    };
    proj_dir = proj_dir.rotate(30.0);

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

        if (proj_pos.x <= 0 or (proj_pos.x + PROJ_SIZE >= WINDOW_WIDTH)) {
            proj_dir.x = -proj_dir.x;
        }
        if (proj_pos.y <= 0 or (proj_pos.y + PROJ_SIZE >= WINDOW_HEIGHT)) {
            proj_dir.y = -proj_dir.y;
        }

        proj_pos.x += DELTA_TIME * PROJ_SPEED * proj_dir.x;
        proj_pos.y += DELTA_TIME * PROJ_SPEED * proj_dir.y;
        // log.debug("proj_pos is [{d}, {d}]", .{ proj_pos.x, proj_pos.y });
        // log.debug("proj_dir is [{d}, {d}]", .{ proj_dir.x, proj_dir.y });

        _ = c.SDL_SetRenderDrawColor(renderer, 0x20, 0x20, 0x40, 0xff);
        _ = c.SDL_RenderClear(renderer);

        const rect = c.SDL_Rect{
            .x = @intFromFloat(proj_pos.x),
            .y = @intFromFloat(proj_pos.y),
            .w = PROJ_SIZE,
            .h = PROJ_SIZE,
        };
        _ = c.SDL_SetRenderDrawColor(renderer, 0xff, 0x20, 0x40, 0xff);
        _ = c.SDL_RenderFillRect(renderer, &rect);

        c.SDL_RenderPresent(renderer);

        c.SDL_Delay(DELTA_TIME_INT);
    }
}
