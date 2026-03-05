const std = @import("std");
const Io = std.Io;

const c = @cImport({@cInclude("SDL3/SDL.h");});
const WIDTH = 1024;
const HEIGHT = 768;
const TIME_BETWEEN_STEP = 1000;

const Item = struct {
    value: u32,
    select_1: bool,
    select_2: bool,
};

pub fn main(init: std.process.Init) !void {
    _ = init;
    _ = c.SDL_Init(c.SDL_INIT_VIDEO);
    const win = c.SDL_CreateWindow("Mandelbrot set", WIDTH, HEIGHT, c.SDL_WINDOW_VULKAN);
    const rend = c.SDL_CreateRenderer(win, null);

    var last_time: u64 = c.SDL_GetTicks();
    var frames: u32 = 0;
    
    const cur_sort = "Bubble_sort";
    while(true) {
        frames += 1;
        var ev: c.SDL_Event = undefined;
        while(c.SDL_PollEvent(&ev)) {
            if(ev.type == c.SDL_EVENT_QUIT) return;
            if(ev.type == c.SDL_EVENT_KEY_DOWN) return;
        }
        _ = c.SDL_SetRenderDrawColor(rend, 0, 0, 0, 255);
        _ = c.SDL_RenderFillRect(rend, null);
        _ = c.SDL_SetRenderDrawColor(rend, 255, 255, 255, 255);
        _ = c.SDL_RenderDebugTextFormat(rend, 0.1, 0.1, "Sorterer med %s", cur_sort);

        _ = c.SDL_RenderPresent(rend);
        if(c.SDL_GetTicks() - last_time > TIME_BETWEEN_STEP) {
            last_time = c.SDL_GetTicks();
            std.debug.print("{} fps\n", .{frames});
            frames = 0;
        }
    }
}
