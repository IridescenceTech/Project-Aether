const std = @import("std");
const builtin = @import("builtin");
const vkgen = @import("Aether-Platform/ext/vulkan/generator/index.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const glfw = b.addModule("glfw", .{
        .root_source_file = .{ .path = "Aether-Platform/ext/zwin/glfw/src/glfw.zig" },
    });

    const zwin = b.addModule("zwin", .{
        .root_source_file = .{ .path = "Aether-Platform/ext/zwin/src/zwin.zig" },
        .imports = &.{
            .{ .name = "glfw", .module = glfw },
        },
    });

    const glad = b.addModule("glad", .{
        .root_source_file = .{ .path = "Aether-Platform/ext/glad/c.zig" },
    });
    glad.addIncludePath(.{ .path = "Aether-Platform/ext/glad/include" });
    glad.addIncludePath(.{ .path = "Aether-Platform/ext/glad/" });

    const stbi = b.addModule("stbi", .{
        .root_source_file = .{ .path = "Aether-Platform/ext/stbi/c.zig" },
    });
    stbi.addIncludePath(.{ .path = "Aether-Platform/ext/stbi/" });

    const gen = vkgen.VkGenerateStep.create(b, "Aether-Platform/ext/vk.xml");

    const shaders = vkgen.ShaderCompileStep.create(
        b,
        &[_][]const u8{ "glslc", "--target-env=vulkan1.2" },
        "-o",
    );
    shaders.add("vert", "Aether-Platform/shaders/basic.vert", .{});
    shaders.add("frag", "Aether-Platform/shaders/basic.frag", .{});

    const platform = b.addModule("platform", .{
        .root_source_file = .{ .path = "Aether-Platform/src/platform.zig" },
        .imports = &.{
            .{ .name = "zwin", .module = zwin },
            .{ .name = "glad", .module = glad },
            .{ .name = "vulkan", .module = gen.getModule() },
            .{ .name = "stbi", .module = stbi },
            .{ .name = "shaders", .module = shaders.getModule() },
        },
    });

    const user = b.addModule("user", .{
        .root_source_file = .{ .path = "src/user.zig" },
    });

    const exe = b.addExecutable(.{
        .name = "Aether",
        .root_source_file = .{ .path = "src/engine.zig" },
        .target = target,
        .optimize = optimize,
    });
    user.addImport("engine", &exe.root_module);
    exe.root_module.addImport("user", user);
    exe.root_module.addImport("platform", platform);
    exe.linkLibC();

    if (builtin.os.tag == .windows) {
        exe.addObjectFile(.{ .path = "libglfw3.a" });
        exe.linkSystemLibrary("opengl32");
        exe.linkSystemLibrary("gdi32");
    } else {
        exe.linkSystemLibrary("glfw");
    }
    exe.addCSourceFile(.{
        .file = .{ .path = "Aether-Platform/ext/glad/src/gl.c" },
        .flags = &[_][]const u8{"-IAether-Platform/ext/glad/include"},
    });
    exe.addCSourceFile(.{
        .file = .{ .path = "Aether-Platform/ext/glad/loader.c" },
        .flags = &[_][]const u8{"-IAether-Platform/ext/glad/"},
    });
    exe.addCSourceFile(.{
        .file = .{ .path = "Aether-Platform/ext/stbi/stb_image.c" },
        .flags = &[_][]const u8{"-IAether-Platform/ext/stbi/"},
    });
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
