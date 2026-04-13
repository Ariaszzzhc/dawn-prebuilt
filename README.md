# Dawn Prebuilt

Pre-built Dawn WebGPU binaries.

## Available Platforms

| Platform | File |
|----------|------|
| Windows x86_64 | `dawn-windows-x86_64.zip` |
| Linux x86_64 | `dawn-linux-x86_64.tar.gz` |
| macOS x86_64 (Intel) | `dawn-macos-x86_64.tar.gz` |
| macOS aarch64 (Apple Silicon) | `dawn-macos-aarch64.tar.gz` |

## Build Configuration

- **Library type**: Monolithic shared library (`.dll` / `.so` / `.dylib`)
- **GPU backends**: Platform defaults
  - Windows: D3D11, D3D12, Vulkan
  - macOS: Metal
  - Linux: OpenGL, Vulkan
- **Tint tools**: Included
- **Excluded**: Samples, tests, benchmarks, fuzzers, protobuf, Node bindings, SwiftShader

## Usage

Download from [Releases](https://github.com/Ariaszzzhc/dawn-prebuilt/releases).

### Zig (build.zig)

```zig
const dawn = b.dependency("dawn", .{});
exe.addIncludePath(dawn.path("include"));
exe.addLibraryPath(dawn.path("lib"));
exe.linkSystemLibrary("dawn");
```

### CMake

```cmake
set(CMAKE_PREFIX_PATH "${CMAKE_PREFIX_PATH};/path/to/dawn")
find_package(Dawn REQUIRED)
target_link_libraries(your_target dawn::webgpu_dawn)
```

## Trigger Build

Manually via GitHub Actions workflow dispatch, or it builds automatically every Monday.
