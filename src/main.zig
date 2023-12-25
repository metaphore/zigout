const c = @cImport({
    @cInclude("SDL2/SDL.h");
});
const math = @import("std").math;
const log = @import("std").log;
const assert = @import("std").debug.assert;

const zlm = @import("zlm/zlm.zig");
const sod = @import("sod.zig");

const WINDOW_WIDTH: i32 = 800;
const WINDOW_HEIGHT: i32 = 640;
const PROJ_SIZE: f32 = 72.0;
const PROJ_HSIZE: f32 = PROJ_SIZE * 0.5;
const PROJ_SPEED: f32 = 720.0;
const DELTA_TIME: f32 = 1.0 / 60.0;
const DELTA_TIME_INT: i32 = @intFromFloat(DELTA_TIME * 1000.0);
const BAR_SIZE = zlm.vec2(128.0, 16.0);
const BAR_HSIZE = BAR_SIZE.scale(0.5);
const BAR_Y: f32 = @as(f32, WINDOW_HEIGHT) - 128;
const BAR_SPEED: f32 = 720.0;

var proj_pos = zlm.Vec2{
    .x = WINDOW_WIDTH / 2,
    .y = WINDOW_HEIGHT / 2,
};
var proj_dir = zlm.vec2(1, 0).rotate(30.0);

var bar_x: f32 = @floatFromInt(WINDOW_WIDTH / 2);
var bar_pos_sod = sod.Sod2.new(2.0, 0.6, 0.0);

const InputState = struct {
    left: bool,
    right: bool,
};
var input = InputState{
    .left = false,
    .right = false,
};

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

    bar_pos_sod.reset(bar_x, BAR_Y);

    var quit = false;
    while (!quit) {
        var event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&event) != 0) {
            switch (event.type) {
                c.SDL_QUIT => {
                    quit = true;
                },
                c.SDL_KEYDOWN => {
                    switch (event.key.keysym.sym) {
                        c.SDLK_q => {
                            quit = true;
                        },
                        c.SDLK_a => {
                            input.left = true;
                        },
                        c.SDLK_d => {
                            input.right = true;
                        },
                        else => {},
                    }
                },
                c.SDL_KEYUP => {
                    switch (event.key.keysym.sym) {
                        c.SDLK_a => {
                            input.left = false;
                        },
                        c.SDLK_d => {
                            input.right = false;
                        },
                        else => {},
                    }
                },
                else => {},
            }
        }

        update(DELTA_TIME);

        render(renderer);
    }
}

fn update(delta_time: f32) void {
    var bar_dir_x: f32 = 0;
    if (input.left) {
        bar_dir_x += -1;
    }
    if (input.right) {
        bar_dir_x += 1;
    }
    bar_x += bar_dir_x * BAR_SPEED * delta_time;
    bar_x = math.clamp(bar_x, BAR_HSIZE.x, @as(f32, WINDOW_WIDTH) - BAR_HSIZE.x);
    bar_pos_sod.update(delta_time, bar_x, BAR_Y);

    if (proj_pos.x - PROJ_HSIZE <= 0 or (proj_pos.x + PROJ_HSIZE >= WINDOW_WIDTH)) {
        proj_dir.x = -proj_dir.x;
    }
    if (proj_pos.y - PROJ_HSIZE <= 0 or (proj_pos.y + PROJ_HSIZE >= WINDOW_HEIGHT)) {
        proj_dir.y = -proj_dir.y;
    }

    // Check platform hit.
    const proj_dst_to_bar_h: f32 = bar_pos_sod.pos_y - (proj_pos.y + PROJ_HSIZE);
    if (proj_dir.y > 0 and
        (proj_dst_to_bar_h > -BAR_HSIZE.y and proj_dst_to_bar_h < BAR_HSIZE.y) and
        (proj_pos.x + PROJ_HSIZE > bar_pos_sod.pos_x - BAR_HSIZE.x and proj_pos.x - PROJ_HSIZE < bar_pos_sod.pos_x + BAR_HSIZE.x))
    {
        // Add a little hit feedback to the platform.
        const feedback: f32 = 640;
        bar_pos_sod.acc_x += feedback * proj_dir.x;
        bar_pos_sod.acc_y += feedback * proj_dir.y;

        proj_dir.y = -proj_dir.y;
    }

    proj_pos.x += delta_time * PROJ_SPEED * proj_dir.x;
    proj_pos.y += delta_time * PROJ_SPEED * proj_dir.y;
}

fn render(renderer: *c.SDL_Renderer) void {
    _ = c.SDL_SetRenderDrawColor(renderer, 0x20, 0x20, 0x40, 0xff);
    _ = c.SDL_RenderClear(renderer);

    const proj_rect = projRect();
    _ = c.SDL_SetRenderDrawColor(renderer, 0xff, 0x20, 0x40, 0xff);
    _ = c.SDL_RenderFillRect(renderer, &proj_rect);

    const bar_rect = barRect();
    _ = c.SDL_SetRenderDrawColor(renderer, 0x20, 0xff, 0x20, 0xff);
    _ = c.SDL_RenderFillRect(renderer, &bar_rect);

    c.SDL_RenderPresent(renderer);

    c.SDL_Delay(DELTA_TIME_INT);
}

fn projRect() c.SDL_Rect {
    return c.SDL_Rect{
        .x = @intFromFloat(proj_pos.x - PROJ_HSIZE),
        .y = @intFromFloat(proj_pos.y - PROJ_HSIZE),
        .w = @intFromFloat(PROJ_SIZE),
        .h = @intFromFloat(PROJ_SIZE),
    };
}

fn barRect() c.SDL_Rect {
    return c.SDL_Rect{
        .x = roundInt(bar_pos_sod.pos_x - BAR_HSIZE.x),
        .y = roundInt(bar_pos_sod.pos_y - BAR_HSIZE.y),
        .w = BAR_SIZE.x,
        .h = BAR_SIZE.y,
    };
}

fn roundInt(value: f32) i32 {
    return @as(i32, @intFromFloat(@round(value)));
}
