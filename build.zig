const std = @import("std");

const DawnPackage = struct {
    dependency_name: []const u8,
    runtime_library: RuntimeArtifact,
    runtime_dependencies: []const RuntimeArtifact = &.{},
    link_library_sub_path: []const u8,
};

const RuntimeArtifact = struct {
    name: []const u8,
    sub_path: []const u8,
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const dawn_package = selectDawnPackage(target);
    addBuildTests(b);

    const dawn_dep = b.lazyDependency(dawn_package.dependency_name, .{}) orelse return;
    const include_dir = dawn_dep.path("include");
    const runtime_library = dawn_dep.path(dawn_package.runtime_library.sub_path);
    const runtime_dir = dawn_dep.path(std.fs.path.dirname(dawn_package.runtime_library.sub_path).?);
    const link_dir = dawn_dep.path(std.fs.path.dirname(dawn_package.link_library_sub_path).?);
    b.addNamedLazyPath(dawn_package.runtime_library.name, runtime_library);
    b.addNamedLazyPath("runtime_dir", runtime_dir);
    for (dawn_package.runtime_dependencies) |runtime_dependency| {
        b.addNamedLazyPath(runtime_dependency.name, dawn_dep.path(runtime_dependency.sub_path));
    }

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

fn addBuildTests(b: *std.Build) void {
    const build_tests = b.addTest(.{
        .name = "webgpu-dawn-build-tests",
        .root_module = b.createModule(.{
            .root_source_file = b.path("build.zig"),
            .target = b.graph.host,
            .optimize = .Debug,
        }),
    });
    const run_build_tests = b.addRunArtifact(build_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_build_tests.step);
}

fn selectDawnPackage(target: std.Build.ResolvedTarget) DawnPackage {
    return selectDawnPackageForTarget(target.result.os.tag, target.result.cpu.arch);
}

fn selectDawnPackageForTarget(os_tag: std.Target.Os.Tag, cpu_arch: std.Target.Cpu.Arch) DawnPackage {
    return switch (os_tag) {
        .linux => switch (cpu_arch) {
            .x86_64 => .{
                .dependency_name = "dawn-linux-x86_64",
                .runtime_library = .{
                    .name = "runtime_library",
                    .sub_path = "lib/libwebgpu_dawn.so",
                },
                .link_library_sub_path = "lib/libwebgpu_dawn.so",
            },
            else => unsupportedTargetTags(os_tag, cpu_arch),
        },
        .macos => switch (cpu_arch) {
            .aarch64 => .{
                .dependency_name = "dawn-macos-aarch64",
                .runtime_library = .{
                    .name = "runtime_library",
                    .sub_path = "lib/libwebgpu_dawn.dylib",
                },
                .link_library_sub_path = "lib/libwebgpu_dawn.dylib",
            },
            .x86_64 => .{
                .dependency_name = "dawn-macos-x86_64",
                .runtime_library = .{
                    .name = "runtime_library",
                    .sub_path = "lib/libwebgpu_dawn.dylib",
                },
                .link_library_sub_path = "lib/libwebgpu_dawn.dylib",
            },
            else => unsupportedTargetTags(os_tag, cpu_arch),
        },
        .windows => switch (cpu_arch) {
            .x86_64 => .{
                .dependency_name = "dawn-windows-x86_64",
                .runtime_library = .{
                    .name = "runtime_library",
                    .sub_path = "bin/webgpu_dawn.dll",
                },
                .runtime_dependencies = &.{
                    .{
                        .name = "d3dcompiler_47_dll",
                        .sub_path = "bin/d3dcompiler_47.dll",
                    },
                },
                .link_library_sub_path = "lib/webgpu_dawn.lib",
            },
            else => unsupportedTargetTags(os_tag, cpu_arch),
        },
        else => unsupportedTargetTags(os_tag, cpu_arch),
    };
}

fn unsupportedTarget(target: std.Build.ResolvedTarget) noreturn {
    unsupportedTargetTags(target.result.os.tag, target.result.cpu.arch);
}

fn unsupportedTargetTags(os_tag: std.Target.Os.Tag, cpu_arch: std.Target.Cpu.Arch) noreturn {
    std.debug.panic("unsupported dawn-prebuilt target: {s}-{s}", .{
        @tagName(os_tag),
        @tagName(cpu_arch),
    });
}

test "windows package exposes webgpu and compiler runtime dlls" {
    const package = selectDawnPackageForTarget(.windows, .x86_64);

    try std.testing.expectEqualStrings("runtime_library", package.runtime_library.name);
    try std.testing.expectEqualStrings("bin/webgpu_dawn.dll", package.runtime_library.sub_path);
    try std.testing.expectEqual(@as(usize, 1), package.runtime_dependencies.len);
    try std.testing.expectEqualStrings("d3dcompiler_47_dll", package.runtime_dependencies[0].name);
    try std.testing.expectEqualStrings("bin/d3dcompiler_47.dll", package.runtime_dependencies[0].sub_path);
}

test "non-windows packages expose only the webgpu runtime library" {
    const linux_package = selectDawnPackageForTarget(.linux, .x86_64);
    const macos_package = selectDawnPackageForTarget(.macos, .aarch64);

    try std.testing.expectEqualStrings("runtime_library", linux_package.runtime_library.name);
    try std.testing.expectEqualStrings("lib/libwebgpu_dawn.so", linux_package.runtime_library.sub_path);
    try std.testing.expectEqual(@as(usize, 0), linux_package.runtime_dependencies.len);

    try std.testing.expectEqualStrings("runtime_library", macos_package.runtime_library.name);
    try std.testing.expectEqualStrings("lib/libwebgpu_dawn.dylib", macos_package.runtime_library.sub_path);
    try std.testing.expectEqual(@as(usize, 0), macos_package.runtime_dependencies.len);
}
