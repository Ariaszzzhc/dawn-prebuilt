const std = @import("std");

const DawnPackage = struct {
    dependency_name: []const u8,
    runtime_library_sub_path: []const u8,
    link_library_sub_path: []const u8,
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const dawn_package = selectDawnPackage(target);

    const dawn_dep = b.lazyDependency(dawn_package.dependency_name, .{}) orelse return;
    const include_dir = dawn_dep.path("include");
    const runtime_dir = dawn_dep.path(std.fs.path.dirname(dawn_package.runtime_library_sub_path).?);
    const link_dir = dawn_dep.path(std.fs.path.dirname(dawn_package.link_library_sub_path).?);

    const c = b.addTranslateC(.{
        .root_source_file = dawn_dep.path("include/dawn/dawn_proc_table.h"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    c.addIncludePath(include_dir);
    c.defineCMacro("WGPU_SHARED_LIBRARY", null);

    const c_module = b.addModule("webgpu-dawn", .{
        .root_source_file = c.getOutput(),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    c_module.addLibraryPath(link_dir);
    c_module.addRPath(runtime_dir);
    c_module.linkSystemLibrary("webgpu_dawn", .{
        .use_pkg_config = .no,
        .preferred_link_mode = .dynamic,
    });
}

fn selectDawnPackage(target: std.Build.ResolvedTarget) DawnPackage {
    return switch (target.result.os.tag) {
        .linux => switch (target.result.cpu.arch) {
            .x86_64 => .{
                .dependency_name = "dawn-linux-x86_64",
                .runtime_library_sub_path = "lib/libwebgpu_dawn.so",
                .link_library_sub_path = "lib/libwebgpu_dawn.so",
            },
            else => unsupportedTarget(target),
        },
        .macos => switch (target.result.cpu.arch) {
            .aarch64 => .{
                .dependency_name = "dawn-macos-aarch64",
                .runtime_library_sub_path = "lib/libwebgpu_dawn.dylib",
                .link_library_sub_path = "lib/libwebgpu_dawn.dylib",
            },
            .x86_64 => .{
                .dependency_name = "dawn-macos-x86_64",
                .runtime_library_sub_path = "lib/libwebgpu_dawn.dylib",
                .link_library_sub_path = "lib/libwebgpu_dawn.dylib",
            },
            else => unsupportedTarget(target),
        },
        .windows => switch (target.result.cpu.arch) {
            .x86_64 => .{
                .dependency_name = "dawn-windows-x86_64",
                .runtime_library_sub_path = "bin/webgpu_dawn.dll",
                .link_library_sub_path = "lib/webgpu_dawn.lib",
            },
            else => unsupportedTarget(target),
        },
        else => unsupportedTarget(target),
    };
}

fn unsupportedTarget(target: std.Build.ResolvedTarget) noreturn {
    std.debug.panic("unsupported dawn-prebuilt target: {s}-{s}", .{
        @tagName(target.result.os.tag),
        @tagName(target.result.cpu.arch),
    });
}
