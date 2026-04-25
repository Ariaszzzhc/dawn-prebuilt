# webgpu-dawn.zig

Zig package wrapper for pre-built Dawn WebGPU binaries.

This repository keeps the Zig package metadata and build integration small. Dawn
itself is not vendored in the git tree. The GitHub Actions workflow builds Dawn
from upstream Chromium/Dawn branches and publishes normal platform-specific Dawn
archives to GitHub Releases. `build.zig.zon` then references those release
archives as lazy dependencies, and `build.zig` selects the archive that matches
the requested Zig target.

## Supported Platforms

| Target           | Release asset               |
| ---------------- | --------------------------- |
| `x86_64-windows` | `dawn-windows-x86_64.zip`   |
| `x86_64-linux`   | `dawn-linux-x86_64.tar.gz`  |
| `x86_64-macos`   | `dawn-macos-x86_64.tar.gz`  |
| `aarch64-macos`  | `dawn-macos-aarch64.tar.gz` |

## Install

Add this repository to your Zig project:

```sh
zig fetch --save=webgpu_dawn git+https://github.com/Ariaszzzhc/webgpu-dawn.zig.git
```

To pin a branch tarball directly:

```sh
zig fetch --save=webgpu_dawn https://github.com/Ariaszzzhc/webgpu-dawn.zig/archive/refs/heads/main.tar.gz
```

## Usage

In your project's `build.zig`:

```zig
const dawn = b.dependency("webgpu_dawn", .{
    .target = target,
    .optimize = optimize,
});

exe.root_module.addImport("webgpu-dawn", dawn.module("webgpu-dawn"));
```

If the executable is installed or run outside Zig's package cache, install the
Dawn runtime library next to it:

```zig
b.installArtifact(exe);

const dawn_runtime = dawn.namedLazyPath("runtime_library");
const install_dawn_runtime = b.addInstallFileWithDir(
    dawn_runtime,
    switch (target.result.os.tag) {
        .windows => .bin,
        .linux, .macos => .lib,
        else => @panic("unsupported webgpu-dawn runtime install target"),
    },
    dawn_runtime.basename(b, null),
);
b.getInstallStep().dependOn(&install_dawn_runtime.step);

if (target.result.os.tag == .windows) {
    const d3dcompiler = dawn.namedLazyPath("d3dcompiler_47_dll");
    const install_d3dcompiler = b.addInstallFileWithDir(
        d3dcompiler,
        .bin,
        d3dcompiler.basename(b, null),
    );
    b.getInstallStep().dependOn(&install_d3dcompiler.step);
}
```

For a `zig build run` step on Windows, add Dawn's runtime directory to `PATH`:

```zig
const run_cmd = b.addRunArtifact(exe);
if (target.result.os.tag == .windows) {
    run_cmd.addPathDir(dawn.namedLazyPath("runtime_dir").getPath(b));
}
```

Then import the translated C API from Zig:

```zig
const dawn = @import("webgpu-dawn");
```

The module is generated with `translate-c` from Dawn's installed C headers. The
package also attaches the matching include path, library path, runtime path, and
`webgpu_dawn` dynamic library link information to the module.

On Windows, importing the module is enough for compilation and linking, but it
does not copy `webgpu_dawn.dll` into the executable directory. Windows does not
support rpath, so the DLL must be either installed next to the executable or made
visible through `PATH`. The package exposes `runtime_library`, `runtime_dir`, and
`d3dcompiler_47_dll` named lazy paths for that purpose.

## Dawn Version

The current package manifest points at release `dawn-chrome-7778`.

This package follows the Chrome Beta channel. Chrome versions have the form
`major.minor.build.patch`; the Dawn branch build number is the `build` segment.
For example, Chrome `147.0.7727.101` maps to Dawn branch `chromium/7727`.
The workflow uses the Linux Chrome Beta version as the canonical desktop Chrome
Beta source.

When bumping Dawn:

1. The weekly GitHub Actions workflow reads the latest Chrome Beta version.
2. It extracts the Chrome build number and resolves the matching Dawn
   `chromium/<build>` branch.
3. If `build.zig.zon` already points at that Chrome build, the workflow exits
   without rebuilding.
4. Otherwise, it builds and publishes the platform archives, computes their Zig
   package hashes, updates `build.zig.zon`, and commits the manifest bump.

The release archives contain the installed Dawn files only. This repository
remains the Zig-facing wrapper.

## Build Configuration

- Library type: monolithic shared library (`.dll`, `.so`, `.dylib`)
- GPU backends: platform defaults
  - Windows: D3D11, D3D12, Vulkan
  - macOS: Metal
  - Linux: OpenGL, Vulkan
- Tint command-line tools are included in release archives
- Samples, tests, benchmarks, fuzzers, protobuf, Node bindings, and SwiftShader
  are excluded

## Build Dawn Archives

The `Build Dawn` workflow runs weekly and can also be run manually.

- Leave `chrome_build` empty to use the latest Chrome Beta build number.
- Set `chrome_build` to build a specific Dawn `chromium/<build>` branch.
- Set `force_rebuild` to rebuild even if `build.zig.zon` already points at the
  selected Chrome build.

When the selected build is new, the workflow builds each supported platform,
publishes the Dawn archives to the corresponding GitHub Release, and updates the
Zig package manifest.
