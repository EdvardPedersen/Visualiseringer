const std = @import("std");

fn add_shader(b: *std.Build, infile: []const u8, outfile: []const u8) void {
    const shaders = b.addSystemCommand(&.{"glslc"});
    shaders.addFileArg(b.path(infile));
    shaders.addArg("-o");
    const shader_outfile = shaders.addOutputFileArg(outfile);
    b.getInstallStep().dependOn(&b.addInstallFileWithDir(shader_outfile, .prefix, outfile).step);
}


pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    add_shader(b, "shader/mandelbrot.frag", "shader.spv");

    const sdl_dep = b.dependency("sdl", .{
        .target = target,
        .optimize = optimize,
        .sanitize_c = .off,
    });
    const sdl_lib = sdl_dep.artifact("SDL3");

    const exe = b.addExecutable(.{
        .name = "Visualiseringer",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    exe.root_module.linkLibrary(sdl_lib);

    b.installArtifact(exe);
    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());

    const sort_exe = b.addExecutable(.{
        .name = "Sorting",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/sort.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    sort_exe.root_module.linkLibrary(sdl_lib);

    b.installArtifact(sort_exe);
    const sort_run_step = b.step("sort", "Run the app");
    const sort_run_cmd = b.addRunArtifact(sort_exe);
    sort_run_step.dependOn(&sort_run_cmd.step);
    sort_run_cmd.step.dependOn(b.getInstallStep());
}
