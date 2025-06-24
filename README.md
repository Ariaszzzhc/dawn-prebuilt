# Dawn Prebuilt

这个仓库用于自动化构建 Google Dawn 项目。它会定时检查 Dawn 仓库中的新 Chromium nightly 分支，并**只构建最新版本号**的分支。

## 功能特性

- 🕒 **定时检查**: 每周五晚上 10 点(中国时间)自动检查新的 `chromium/*` 分支
- 🎯 **智能选择**: 如果发现多个新分支，只构建版本号最大的那个
- 🔨 **跨平台构建**: 自动构建 Linux、macOS 和 Windows 三个平台
- 📦 **自动发布**: 将构建产物发布到 GitHub Releases
- 🧹 **自动清理**: 保留最新的 10 个发布版本

## 工作流程

1. **分支检查**: 每周五 UTC 14:00 (中国时间 22:00) 检查 Dawn 仓库的 `refs/heads/chromium/*` 分支
2. **版本筛选**: 如果发现多个新分支，提取版本号并**只选择最新的**进行构建
3. **跨平台构建**: 同时在 Ubuntu、macOS 和 Windows 上构建
4. **打包发布**: 将构建产物打包为 ZIP 格式并创建 GitHub Release

## 分支命名规则

- 源分支格式: `refs/heads/chromium/7258`
- Release 标签: `chromium/7258`
- 版本号: `7258` (对应 Chromium nightly build 版本)

## 智能构建逻辑

**场景示例:**

- 如果某天发现新分支: `chromium/7256`, `chromium/7258`, `chromium/7260`
- 系统会自动选择版本号最大的 `chromium/7260` 进行构建
- 避免重复构建，节省资源和时间

## 构建产物

每个 Release 包含三个平台的构建:

- `dawn-chromium-XXXX-linux-x64.zip` - Linux x64 构建
- `dawn-chromium-XXXX-macos-x64.zip` - macOS x64 构建
- `dawn-chromium-XXXX-windows-x64.zip` - Windows x64 构建
- `BUILD_INFO.txt` - 构建信息（包含在每个压缩包内）

每个压缩包包含:

- Dawn 库文件和头文件
- 编译后的二进制文件
- 构建信息文件

## 手动触发

除了定时执行，你也可以在 GitHub Actions 页面手动触发工作流:

1. 进入 "Actions" 标签页
2. 选择 "Check Dawn Branches and Build Latest" 工作流
3. 点击 "Run workflow"

## 使用构建产物

### Linux

```bash
# 下载最新构建
wget https://github.com/YOUR_USERNAME/dawn-prebuilt/releases/latest/download/dawn-chromium-XXXX-linux-x64.zip

# 解压使用
unzip dawn-chromium-XXXX-linux-x64.zip
cd dawn-install
cat BUILD_INFO.txt  # 查看构建信息
```

### macOS

```bash
# 下载最新构建
curl -L -O https://github.com/YOUR_USERNAME/dawn-prebuilt/releases/latest/download/dawn-chromium-XXXX-macos-x64.zip

# 解压使用
unzip dawn-chromium-XXXX-macos-x64.zip
cd dawn-install
cat BUILD_INFO.txt  # 查看构建信息
```

### Windows

```powershell
# 下载并解压
Invoke-WebRequest -Uri "https://github.com/YOUR_USERNAME/dawn-prebuilt/releases/latest/download/dawn-chromium-XXXX-windows-x64.zip" -OutFile "dawn-windows.zip"
Expand-Archive -Path "dawn-windows.zip" -DestinationPath "."
cd dawn-install
Get-Content BUILD_INFO.txt  # 查看构建信息
```

## 文件说明

- `.github/workflows/build.yml` - 主要的 GitHub Actions 工作流
- `previous_branches.txt` - 记录已处理的分支（自动生成和更新）
- `README.md` - 项目说明文档

## 配置说明

工作流使用以下环境变量:

- `DAWN_REPO`: Dawn 仓库地址 (https://dawn.googlesource.com/dawn)
- `GITHUB_TOKEN`: GitHub API 访问令牌（自动提供）

## 平台特性

### Linux 构建

- 使用 Ubuntu Latest
- 包含完整的 X11 开发库支持
- 支持 Vulkan 和 OpenGL ES 后端

### macOS 构建

- 使用 macOS Latest
- 支持 Metal 后端
- 通过 Homebrew 安装依赖

### Windows 构建

- 使用 Windows Latest
- 支持 D3D12 和 D3D11 后端
- 包含最新的 Windows SDK (26100)

## 优势

✅ **跨平台支持**: 同时提供 Linux、macOS、Windows 三个平台的构建
✅ **避免重复构建**: 每周只构建最新版本，避免资源浪费
✅ **自动化管理**: 无需手动干预，全自动运行
✅ **版本追踪**: 详细记录每次构建的版本信息
✅ **存储优化**: 自动清理旧版本，节省存储空间
✅ **统一格式**: 所有平台都使用 ZIP 格式，便于使用

## 注意事项

- 构建环境为各平台的 Latest 版本
- 支持 Linux x64、macOS x64、Windows x64 平台
- 自动保留最新 10 个版本，旧版本会被自动删除
- 需要仓库具有 Actions 和 Releases 权限
- **重要**: 每周只会构建版本号最大的新分支
- Windows 构建需要 D3D12 支持，使用最新 Windows SDK

## 监控和调试

你可以在 GitHub Actions 页面查看:

- 工作流执行历史和日志
- 每次构建选择的分支和版本号
- 三个平台的构建过程详细输出
- 错误信息和调试信息

如果需要修改检查频率或构建配置，请编辑 `.github/workflows/build.yml` 文件。

---

**Created by:** @Ariaszzzhc
**Last Updated:** 2025-06-24
