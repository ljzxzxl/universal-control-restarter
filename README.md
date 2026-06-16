# UniversalControlRestart

[English](#english) | [中文](#中文)

## English

A tiny macOS utility that restarts Universal Control without rebooting your Mac.

Universal Control can occasionally get stuck with the underlying services still alive but the active cross-device session gone. This app does one focused thing: it restarts `/System/Library/CoreServices/UniversalControl.app`, shows the process in a small terminal-style window, and closes itself after a successful restart.

The release app is a universal macOS build for both Intel Macs and Apple Silicon Macs.

On first use, the app asks for confirmation before restarting Universal Control. After you confirm once, later launches skip the confirmation dialog. The restart process is shown in a terminal-style window and closes automatically after completion.

### Download

Download the latest `UniversalControlRestart-*.zip` from [GitHub Releases](https://github.com/ljzxzxl/universal-control-restarter/releases), unzip it, move `UniversalControlRestart.app` to the Applications folder, then double-click it to run.

### What It Does

- Finds the current `UniversalControl` process.
- Tries a normal `TERM`, then falls back to `KILL` if the process ignores it.
- Reopens `/System/Library/CoreServices/UniversalControl.app`.
- Prints the old and new PID, `launchctl` state, and basic connection checks.
- Exits automatically when the restart succeeds.

It does not require `sudo`, does not change system settings, and does not collect telemetry.

### Build

Requirements:

- macOS 12 or later
- Xcode Command Line Tools

```sh
git clone git@github.com:ljzxzxl/universal-control-restarter.git
cd universal-control-restarter
./scripts/build.sh
```

The built app will be written to:

```text
build/UniversalControlRestart.app
```

To install locally:

```sh
cp -R build/UniversalControlRestart.app /Applications/
```

### Package

```sh
./scripts/package.sh
```

This creates a zip archive in `dist/` that can be attached to a GitHub Release.

### Gatekeeper Note

Local builds are ad-hoc signed. If you download an unsigned release zip from GitHub, macOS may require right-clicking the app and choosing **Open** the first time. For broad distribution, build with a Developer ID certificate and notarize the zip or DMG.

### Troubleshooting Command

The app is a GUI wrapper around the practical recovery command:

```sh
pkill -9 -x UniversalControl
open -g /System/Library/CoreServices/UniversalControl.app
```

### License

MIT

## 中文

一个很小的 macOS 工具，用来在不重启整台 Mac 的情况下重启“通用控制”。

有时“通用控制”会进入一种尴尬状态：相关系统服务还活着，但跨设备键盘/鼠标会话已经断开。这个 App 只做一件事：重启 `/System/Library/CoreServices/UniversalControl.app`，在一个终端风格的小窗口里显示执行过程，并在重启成功后自动关闭。

Release 版本是 macOS universal build，同时支持 Intel Mac 和 Apple Silicon Mac。

首次使用时，App 会先弹出确认框；用户确认一次后，后续启动不再重复弹出确认框。重启过程会在终端风格窗口里显示每一步执行过程，完成后自动关闭。

### 下载使用

到 [GitHub Releases](https://github.com/ljzxzxl/universal-control-restarter/releases) 下载最新的 `UniversalControlRestart-*.zip`，解压后把 `UniversalControlRestart.app` 拖到“应用程序”中，双击运行即可。

第一次打开时，如果 macOS 提示无法验证开发者，可以在 Finder 里右键点击 App，选择 **打开**，再确认一次。后续就可以直接双击运行。

### 它会做什么

- 查找当前的 `UniversalControl` 进程。
- 先尝试正常 `TERM` 结束进程，如果进程没有退出，再使用 `KILL`。
- 重新打开 `/System/Library/CoreServices/UniversalControl.app`。
- 在窗口里显示旧 PID、新 PID、`launchctl` 状态和基础连接检查。
- 重启成功后自动退出。

它不需要 `sudo`，不会修改系统设置，也不会收集任何遥测数据。

### 从源码构建

要求：

- macOS 12 或更高版本
- Xcode Command Line Tools

```sh
git clone git@github.com:ljzxzxl/universal-control-restarter.git
cd universal-control-restarter
./scripts/build.sh
```

构建后的 App 会生成在：

```text
build/UniversalControlRestart.app
```

本地安装：

```sh
cp -R build/UniversalControlRestart.app /Applications/
```

### 打包

```sh
./scripts/package.sh
```

脚本会在 `dist/` 目录生成 zip 文件和对应的 SHA256 校验文件，可以直接上传到 GitHub Release。

### Gatekeeper 提示

当前本地构建使用 ad-hoc 签名。公开下载的 zip 如果没有 Developer ID 签名和 notarization，macOS 可能会要求首次通过右键菜单打开。更正式的大范围分发建议使用 Apple Developer ID 签名并完成 notarization。

### 对应命令

这个 App 本质上是下面这组恢复命令的 GUI 包装：

```sh
pkill -9 -x UniversalControl
open -g /System/Library/CoreServices/UniversalControl.app
```

### 许可证

MIT
