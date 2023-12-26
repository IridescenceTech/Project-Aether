const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "Application",
        .root_source_file = .{ .path = "src/app/applib.zig" },
        .target = target,
        .optimize = optimize,
    });

    const engine = b.addModule(
        "engine",
        .{
            .source_file = .{ .path = "src/interface.zig" },
        },
    );

    lib.addModule("engine", engine);
    b.installArtifact(lib);

    const types = b.addModule(
        "types",
        .{
            .source_file = .{ .path = "src/types.zig" },
        },
    );

    const platform = b.addModule(
        "platform",
        .{
            .source_file = .{ .path = "src/platform/platform.zig" },
            .dependencies = &.{
                .{ .name = "types", .module = types },
            },
        },
    );

    const exe = b.addExecutable(.{
        .name = "Project-Aether",
        .root_source_file = .{ .path = "src/core/engine.zig" },
        .target = target,
        .optimize = optimize,
    });
    exe.linkLibrary(lib);
    exe.addModule("types", types);
    exe.addModule("platform", platform);

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/engine.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
