const std = @import("std");
const Io = std.Io;

const c = @cImport({@cInclude("SDL3/SDL.h");});
const shader = @embedFile("shader.spv");

const WIDTH = 1024;
const HEIGHT = 768;
const MAX_ITERATIONS = 255;

pub fn kernel(pixels: [*]u32) void {
    for(0..HEIGHT) |y| {
        const y0: f64 = ((@as(f64, @floatFromInt(y)) / @as(f64, @floatFromInt(HEIGHT))) * 2.24) - 1.12;
        for(0..WIDTH) |x| {
            const x0: f64 = ((@as(f64, @floatFromInt(x)) / @as(f64, @floatFromInt(WIDTH))) * 2.47) - 2;
            var xf: f64 = 0;
            var yf: f64 = 0;
            var iteration: u32 = 0;
            while(xf*xf + yf*yf < 4 and iteration < MAX_ITERATIONS) {
                const xtemp: f64 = xf*xf - yf*yf + x0;
                yf = 2*xf*yf + y0;
                xf = xtemp;
                iteration += 1;
            }
            pixels[x + (y * WIDTH)] = iteration << 8 | 0xff;
        }
    }
}


pub fn main(init: std.process.Init) !void {
    _ = init;

    _ = c.SDL_Init(c.SDL_INIT_VIDEO);
    const win = c.SDL_CreateWindow("Mandelbrot set", WIDTH, HEIGHT, c.SDL_WINDOW_VULKAN);
    const rend = c.SDL_CreateGPURenderer(null, win);
    const tex: ?*c.SDL_Texture = c.SDL_CreateTexture(rend, c.SDL_PIXELFORMAT_RGBA8888, c.SDL_TEXTUREACCESS_STREAMING, WIDTH, HEIGHT);

    var last_time: u64 = c.SDL_GetTicks();
    var frames: u32 = 0;
    var use_gpu: bool = true;
    const dev = c.SDL_GetGPURendererDevice(rend);
    if(dev == null) {
        std.debug.print("We have issue!\n", .{});
        std.debug.print("{s}\n", .{c.SDL_GetError()});
    }
    const shd = c.SDL_CreateGPUShader(dev, &.{.code_size = shader.len, .code = @ptrCast(shader.ptr), .entrypoint = "main", .num_samplers = 0, .num_storage_textures = 0, .num_storage_buffers = 0, .num_uniform_buffers = 0, .props = 0, .format = c.SDL_GPU_SHADERFORMAT_SPIRV, .stage = c.SDL_GPU_SHADERSTAGE_FRAGMENT});
    if(shd == null) {
        std.debug.print("We have issue!\n", .{});
        std.debug.print("{s}\n", .{c.SDL_GetError()});
    }
    const rend_state = c.SDL_CreateGPURenderState(rend, @constCast(&c.SDL_GPURenderStateCreateInfo{.fragment_shader = shd, .num_sampler_bindings = 0, .sampler_bindings = null, .num_storage_textures = 0, .storage_textures = 0, .num_storage_buffers = 0, .storage_buffers = null, .props = 0}));
    
    if(!c.SDL_SetGPURenderState(rend, rend_state)) std.debug.print("Unable to set render state\n", .{});
    var fps: u32 = 0;
    _ = c.SDL_SetRenderDrawColor(rend, 255, 255, 255, 255);
    while(true) {
        frames += 1;
        var ev: c.SDL_Event = undefined;
        while(c.SDL_PollEvent(&ev)) {
            if(ev.type == c.SDL_EVENT_QUIT) return;
            if(ev.type == c.SDL_EVENT_KEY_DOWN) {
                use_gpu = !use_gpu;
                if(use_gpu) {
                    _ = c.SDL_SetGPURenderState(rend, rend_state);
                } else {
                    _ = c.SDL_SetGPURenderState(rend, null);
                }
            }
        }

        if(!use_gpu) {
            var pixels: ?*anyopaque = undefined;
            var pitch: i32 = undefined;
            _ = c.SDL_LockTexture(tex, null, &pixels, &pitch);
            kernel(@ptrCast(@alignCast(pixels)));
            c.SDL_UnlockTexture(tex);
            _ = c.SDL_RenderTexture(rend, tex, null, null);
            _ = c.SDL_RenderDebugTextFormat(rend, 0.1, 0.1, "CPU %d fps", fps);
        } else {
            _ = c.SDL_SetGPURenderState(rend, rend_state);
            _ = c.SDL_RenderFillRect(rend, null);
            _ = c.SDL_SetGPURenderState(rend, null);
            _ = c.SDL_RenderDebugTextFormat(rend, 0.1, 0.1, "GPU %d fps", fps);
        }

        _ = c.SDL_RenderPresent(rend);
        if(c.SDL_GetTicks() - last_time > 1000) {
            last_time = c.SDL_GetTicks();
            std.debug.print("{} fps\n", .{frames});
            fps = frames;
            frames = 0;
        }
    }
}
