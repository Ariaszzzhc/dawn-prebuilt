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

Then import the translated C API from Zig:

```zig
const dawn = @import("webgpu-dawn");
```

The module is generated with `translate-c` from Dawn's installed C headers. The
package also attaches the matching include path, library path, runtime path, and
`webgpu_dawn` dynamic library link information to the module.

## Dawn Version

The current package manifest points at release `dawn-chrome-7778`.

When bumping Dawn:

1. Run the GitHub Actions workflow with the desired Chrome build number.
2. Wait for the platform archives to be published in GitHub Releases.
3. Update the release URLs and hashes in `build.zig.zon`.

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

Run the `Build Dawn` GitHub Actions workflow manually with a Chrome build number.
The workflow resolves the matching Dawn `chromium/<build>` branch, builds each
supported platform, and publishes the Dawn archives to the corresponding GitHub
Release.
