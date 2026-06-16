# UniversalControlRestart

A tiny macOS utility that restarts Universal Control without rebooting your Mac.

Universal Control can occasionally get stuck with the underlying services still alive but the active cross-device session gone. This app does one focused thing: it restarts `/System/Library/CoreServices/UniversalControl.app`, shows the process in a small terminal-style window, and closes itself after a successful restart.

## What It Does

- Finds the current `UniversalControl` process.
- Tries a normal `TERM`, then falls back to `KILL` if the process ignores it.
- Reopens `/System/Library/CoreServices/UniversalControl.app`.
- Prints the old and new PID, `launchctl` state, and basic connection checks.
- Exits automatically when the restart succeeds.

It does not require `sudo`, does not change system settings, and does not collect telemetry.

## Build

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

## Package

```sh
./scripts/package.sh
```

This creates a zip archive in `dist/` that can be attached to a GitHub Release.

## Gatekeeper Note

Local builds are ad-hoc signed. If you download an unsigned release zip from GitHub, macOS may require right-clicking the app and choosing **Open** the first time. For broad distribution, build with a Developer ID certificate and notarize the zip or DMG.

## Troubleshooting Command

The app is a GUI wrapper around the practical recovery command:

```sh
pkill -9 -x UniversalControl
open -g /System/Library/CoreServices/UniversalControl.app
```

## License

MIT
